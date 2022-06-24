{{/* vim: set filetype=mustache: */}}

{{/*
  Creates a template for the container portions of workloads. Since it is
  possible to configure multiple containers in a single pod, to reduce code
  duplication, this additional helper procedure/function is introduced.
*/}}
{{- define "containerTemplate" }}
{{- $containerPortList := (list) }}
{{- range $key, $value := .Values.services }}
{{- range $containerPort := $value.portConfigs }}
{{- $containerPortList = mustAppend $containerPortList $containerPort }}
{{- end }}
{{- end }}
- {{ if .Values.argument -}}
  args:
    {{- range $argument := ( mustRegexSplit " " .Values.argument -1 ) }}
    - {{ $argument | quote }}
    {{- end }}
  {{ end -}}
  {{ if or .configArgs.configOutput.configString .secretArgs.secretOutput.secretString -}}
  {{/*
    Implement all environment variables as config maps. That is,
    excluding secrets, all environment variables are defined solely in
    the 'config' directory.
  */ -}}
  env:
    {{- if .configArgs.configOutput.configString }}
    {{- range $value := .configArgs.config.configurations.strings }}
    - name: {{ $value }}
      valueFrom:
        configMapKeyRef:
          name: {{ template "fullname" $ }}-cm
          key: {{ $value }}
    {{- end }}
    {{- end }}
    {{- if .secretArgs.secretOutput.secretString }}
    {{- range $value := .secretArgs.secret.secrets.strings }}
    - name: {{ $value }}
      valueFrom:
        secretKeyRef:
          name: {{ template "fullname" $ }}-secret
          key: {{ $value }}
    {{- end }}
    {{- end }}
  {{ end -}}
  {{ if .Values.command -}}
  command:
    {{- range $command := ( mustRegexSplit " " .Values.command -1 ) }}
    - {{ $command | quote }}
    {{- end }}
  {{ end -}}
  {{- include "imageNameTag" .Values }}
  imagePullPolicy: {{ .Values.imagePullPolicy | default "Always" }}
  {{- if .Values.liveness }}
  livenessProbe:
    {{- $probeArgs := dict "probe" .Values.liveness "containerPortList" $containerPortList }}
    {{- include "probe" $probeArgs | indent 4 }}
  {{- end }}
  {{- if .Values.name }}
  name: {{ .Values.name }}
  {{- else }}
  name: {{ template "fullname" . }}
  {{- end }}
  {{- include "workloadPortConfig" .Values.services | indent 2 }}
  {{- if .Values.readiness }}
  readinessProbe:
    {{- $probeArgs := dict "probe" .Values.readiness "containerPortList" $containerPortList }}
    {{- include "probe" $probeArgs | indent 4 }}
  {{- end }}
  {{- if .Values.resources }}
  resources:
    {{- toYaml .Values.resources | nindent 4 }}
  {{- end }}
  {{- if .Values.startup }}
  startupProbe:
    {{- $probeArgs := dict "probe" .Values.startup "containerPortList" $containerPortList }}
    {{- include "probe" $probeArgs | indent 4 }}
  {{- end }}
  {{- /*
    Configure volume mounts to the working container. Note that
    environment variables from config maps and secrets do not require
    a volume mount to be defined.
  */}}
  {{- if or .configArgs.configOutput.configFile .secretArgs.secretOutput.secretFile }}
  volumeMounts:
    {{- if .configArgs.configOutput.configFile }}
    - mountPath: /mount/config
      name: config
    {{- end }}
    {{- if .secretArgs.secretOutput.secretFile }}
    - mountPath: /mount/secret
      name: secret
    {{- end }}
  {{- end }}
{{- end }}
