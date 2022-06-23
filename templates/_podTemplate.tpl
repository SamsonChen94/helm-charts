{{/* vim: set filetype=mustache: */}}

{{/*
  Creates pod template portions of workloads. A few Kubernetes resources
  inherently repeats this configuration since all non-disabled workloads must
  result in pods being created. Deployments, stateful sets, daemon sets, and
  cron jobs are the some of the resources to require pod templates.
*/}}
{{- define "podSpecTemplate" }}
{{- $configArgs := dict "config" .Values "configOutput" (dict) }}
{{- include "configEnabledCheck" $configArgs }}
{{- $secretArgs := dict "secret" .Values "secretOutput" (dict) }}
{{- include "secretEnabledCheck" $secretArgs }}
template:
  metadata:
    {{- /*
      Checksum annotations will allow kubelet to check for any changes made
      to a specific YAML file and redeploy this workload even when no changes
      were made to this file directly. Effectively triggering a redeployment
      of this workload when configurations or secrets have been altered.
    */}}
    {{- if or ( or $configArgs.configOutput.configFile $configArgs.configOutput.configString ) ( or $secretArgs.secretOutput.secretFile $secretArgs.secretOutput.secretString ) }}
    annotations:
      {{- if or $configArgs.configOutput.configFile $configArgs.configOutput.configString }}
      checksum/config: {{ include ( print .Template.BasePath "/configMap.yaml" ) . | sha256sum }}
      {{- end }}
      {{- if or $secretArgs.secretOutput.secretFile $secretArgs.secretOutput.secretString }}
      checksum/secret: {{ include ( print .Template.BasePath "/secret.yaml" ) . | sha256sum }}
      {{- end }}
    {{- end }}
    labels:
      {{- include "labels" . | nindent 6 }}
  spec:
    containers:
      - {{ if .Values.argument -}}
        args:
          {{- range $argument := ( mustRegexSplit " " .Values.argument -1 ) }}
          - {{ $argument | quote }}
          {{- end }}
        {{ end -}}
        {{ if or $configArgs.configOutput.configString $secretArgs.secretOutput.secretString -}}
        {{/*
          Implement all environment variables as config maps. That is,
          excluding secrets, all environment variables are defined solely in
          the 'config' directory.
        */ -}}
        env:
          {{- if $configArgs.configOutput.configString }}
          {{- range $value := $configArgs.config.configurations.strings }}
          - name: {{ $value }}
            valueFrom:
              configMapKeyRef:
                name: {{ template "fullname" $ }}-cm
                key: {{ $value }}
          {{- end }}
          {{- end }}
          {{- if $secretArgs.secretOutput.secretString }}
          {{- range $value := $secretArgs.secret.secrets.strings }}
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
        name: {{ template "fullname" . }}
        {{- include "workloadPortConfig" .Values.services | indent 8 }}
        {{- if .Values.resources }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- end }}
        {{- /*
          Configure volume mounts to the working container. Note that
          environment variables from config maps and secrets do not require
          a volume mount to be defined.
        */}}
        {{- if or $configArgs.configOutput.configFile $secretArgs.secretOutput.secretFile }}
        volumeMounts:
          {{- if $configArgs.configOutput.configFile }}
          - mountPath: /mount/config
            name: config
          {{- end }}
          {{- if $secretArgs.secretOutput.secretFile }}
          - mountPath: /mount/secret
            name: secret
          {{- end }}
        {{- end }}
      {{- /*
        In some use cases, multiple additional containers are necessary for
        the business functions in a single pod. In such cases, additional
        containers can be configured to run alongside the aforementioned
        container. For more information on different patterns of
        multi-container deployments, read up 'Container Design Patterns'.
      */}}
      {{- $additionalContainerConfigFileEnabled := false }}
      {{- $additionalContainerSecretFileEnabled := false }}
      {{- if .Values.additionalContainers }}
      {{- range $additionalContainer := .Values.additionalContainers }}
      {{- $_ := set $additionalContainer "configFiles" $.Values.configFiles }}
      {{- $_ := set $additionalContainer "configStrings" $.Values.configStrings }}
      {{- $additionalConfigArgs := dict "config" $additionalContainer "configOutput" (dict) }}
      {{- include "configEnabledCheck" $additionalConfigArgs }}
      {{- $additionalSecretArgs := dict "secret" $additionalContainer "secretOutput" (dict) }}
      {{- include "secretEnabledCheck" $additionalSecretArgs }}
      - {{ if $additionalContainer.argument -}}
        args:
          {{- range $argument := ( mustRegexSplit " " $additionalContainer.argument -1 ) }}
          - {{ $argument | quote }}
          {{- end }}
        {{ end -}}
        {{ if or $additionalConfigArgs.configOutput.configString $additionalSecretArgs.secretOutput.secretString -}}
        env:
          {{- if $additionalConfigArgs.configOutput.configString }}
          {{- range $value := $additionalConfigArgs.config.configurations.strings }}
          - name: {{ $value }}
            valueFrom:
              configMapKeyRef:
                name: {{ template "fullname" $ }}-cm
                key: {{ $value }}
          {{- end }}
          {{- end }}
          {{- if $additionalSecretArgs.secretOutput.secretString }}
          {{- range $value := $additionalSecretArgs.secret.secrets.strings }}
          - name: {{ $value }}
            valueFrom:
              secretKeyRef:
                name: {{ template "fullname" $ }}-secret
                key: {{ $value }}
          {{- end }}
          {{- end }}
        {{ end -}}
        {{ if $additionalContainer.command -}}
        command:
          {{- range $command := ( mustRegexSplit " " $additionalContainer.command -1 ) }}
          - {{ $command | quote }}
          {{- end }}
        {{ end -}}
        {{- include "imageNameTag" $additionalContainer }}
        imagePullPolicy: {{ $additionalContainer.imagePullPolicy | default "Always" }}
        name: {{ $additionalContainer.name }}
        {{- include "workloadPortConfig" $additionalContainer.services | indent 8 }}
        {{- if $additionalContainer.resources }}
        resources:
          {{- toYaml $additionalContainer.resources | nindent 10 }}
        {{- end }}
        {{- /*
          Configure volume mounts to the working container. Note that
          environment variables from config maps and secrets do not require
          a volume mount to be defined.
        */}}
        {{- if or $additionalConfigArgs.configOutput.configFile $additionalSecretArgs.secretOutput.secretFile }}
        volumeMounts:
          {{- if $additionalConfigArgs.configOutput.configFile }}
          {{- $additionalContainerConfigFileEnabled = true }}
          - mountPath: /mount/config
            name: config
          {{- end }}
          {{- if $additionalSecretArgs.secretOutput.secretFile }}
          {{- $additionalContainerSecretFileEnabled = true }}
          - mountPath: /mount/secret
            name: secret
          {{- end }}
        {{- end }}
      {{- end }}
      {{- end }}
    dnsPolicy: ClusterFirst
    restartPolicy: Always
    terminationGracePeriodSeconds: 10
    {{- /*
      Configure volume mounts to the Kubernetes node. Note that environment
      variables from config maps and secrets do not required a volume to be
      defined.
    */}}
    {{- if or ( or $configArgs.configOutput.configFile $additionalContainerConfigFileEnabled ) ( or $secretArgs.secretOutput.secretFile $additionalContainerSecretFileEnabled ) }}
    volumes:
      {{- if or $configArgs.configOutput.configFile $additionalContainerConfigFileEnabled }}
      - configMap:
          name: {{ template "fullname" . }}-cm
        name: config
      {{- end }}
      {{- if or $secretArgs.secretOutput.secretFile $additionalContainerSecretFileEnabled }}
      - name: secret
        secret:
          defaultMode: 420
          secretName: {{ template "fullname" . }}-secret
      {{- end }}
    {{- end }}
{{- end }}
