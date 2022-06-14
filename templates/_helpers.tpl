{{/* vim: set filetype=mustache: */}}

{{/*
  Create a default fully qualified app name. Truncate at 63 chars because some
  Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Generate basic labels
*/}}
{{- define "labels" -}}
{{ include "selectorLabels" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/*
  Selector labels. Meant to be used in spec.selector in many Kubernetes
  resources. Differs from basic labels due to selector labels being immutable.
*/}}
{{- define "selectorLabels" -}}
app: {{ template "fullname" . }}
{{- end -}}

{{/*
  Image name and tag. Meant to be used in spec.template.spec.containers[0].image
  This should handle errors as well
*/}}
{{- define "imageNameTag" -}}
  {{- if not .imageName -}}
    {{- fail ( printf "\n\nError --> 'imageName' not defined\n" ) -}}
  {{- end -}}
  {{- if not .imageTag -}}
    {{- fail ( printf "\n\nError --> imageTag not found, use --set in the helm command 'helm --set imageTag=\"v1.0.0\" ...'\n" ) -}}
  {{- end -}}
  image: {{ .imageName }}:{{ .imageTag }}
{{- end -}}

{{/*
  Check if the different configurations are enabled. Returns the 'configString'
  and 'configFile', both as booleans.
  Note: Helm templates do not implement full-fledge functions. Below is an
        implementation of 'returning' a result, abide in a very weird way
  Reference: https://dastrobu.medium.com/are-helm-charts-turing-complete-46ea7a540ca2
             https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "configEnabledCheck" -}}
  {{- if .config -}}
    {{- if and .config.files .config.strings -}}
      {{- $_ := set .configOutput "configFile" true }}
      {{- $_ := set .configOutput "configString" true }}
    {{- else if .config.files -}}
      {{- $_ := set .configOutput "configFile" true }}
      {{- $_ := set .configOutput "configString" false }}
    {{- else if .config.strings -}}
      {{- $_ := set .configOutput "configFile" false }}
      {{- $_ := set .configOutput "configString" true }}
    {{- else -}}
      {{- $_ := set .configOutput "configFile" false }}
      {{- $_ := set .configOutput "configString" false }}
    {{- end -}}
  {{- else -}}
    {{- $_ := set .configOutput "configFile" false }}
    {{- $_ := set .configOutput "configString" false }}
  {{- end -}}
{{- end -}}

{{/*
  Check if horizontal pod autoscaler is enabled. Returns 'hpaEnabled' as a boolean.
  Also checks if min replica is a valid number (not greater than max replica).
  Note: Helm templates do not implement full-fledge functions. Below is an
        implementation of 'returning' a result, abide in a very weird way
  Reference: https://dastrobu.medium.com/are-helm-charts-turing-complete-46ea7a540ca2
             https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "hpaEnabled" -}}
  {{- if .hpa -}}
    {{- if .hpa.enabled -}}
      {{- if gt .hpa.min .hpa.max -}}
      {{- fail ( printf "\n\nError --> minReplicas cannot be a value larger than maxReplicas\n" ) -}}
      {{- end -}}
      {{- $_ := set .hpaOutput "hpaEnabled" true }}
    {{- else -}}
      {{- $_ := set .hpaOutput "hpaEnabled" false }}
    {{- end -}}
  {{- else -}}
    {{- $_ := set .hpaOutput "hpaEnabled" false }}
  {{- end -}}
{{- end -}}

{{/*
  Checks for the following:
    1. The validity of containerProtocol, if any
    2. The validity of containerPort
    3. The validity of servicePort, if any
*/}}
{{- define "checkPortInfo" -}}
  {{- if .containerProtocol -}}
    {{- if and ( and ( ne .containerProtocol "TCP" ) ( ne .containerProtocol "UDP" ) ) ( ne .containerProtocol "SCTP" ) -}}
      {{- fail ( printf "\n\nError --> unsupported container port protocol %s for %s\n" .containerProtocol .name ) -}}
    {{- end -}}
  {{- end -}}
  {{- if or ( lt ( .containerPort | int ) 1 ) ( gt ( .containerPort | int ) 65535 ) -}}
    {{- fail ( printf "\n\nError --> unsupported container port number %s for %s\n" ( .containerPort | toString ) .name ) -}}
  {{- end -}}
  {{- if and .servicePort ( or ( lt ( .servicePort | int ) 1 ) ( gt ( .servicePort | int ) 65535 ) ) -}}
    {{- fail ( printf "\n\nError --> unsupported service port number %s for %s\n" ( .servicePort | toString ) .name ) -}}
  {{- end -}}
{{- end -}}

{{/*
  Define ports used in workloads. Also checks the validity of each container
  port information. Returns correct container port configuration while errors
  out if any data provided is invalid.
*/}}
{{- define "workloadPortConfig" }}
  {{- if . }}
ports:
    {{- range $services := . }}
      {{- range $containerPorts := $services.portConfigs }}
        {{- include "checkPortInfo" $containerPorts }}
  - containerPort: {{ $containerPorts.containerPort }}
    name: {{ $containerPorts.name }}
    protocol: {{ $containerPorts.containerProtocol | default "TCP" }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
  Define ports used in services. Also checks the validity of each service port
  information. Returns correct service port configuration while errors out if
  any data provided is invalid.
*/}}
{{- define "servicePorts" -}}
  {{- $servicePortList := (list) -}}
  {{- range $port := . -}}
    {{- include "checkPortInfo" $port -}}
    {{- if has ( cat ( $port.containerProtocol | default "TCP" ) ( $port.servicePort | default $port.containerPort | toString ) ) $servicePortList -}}
    {{- fail ( printf "\n\nError --> repeating service port number %s (%s) for %s\n" ( $port.servicePort | toString ) $port.containerProtocol $port.name ) -}}
    {{- end -}}
    {{- $checkRepeatingServicePort := cat ( $port.containerProtocol | default "TCP" ) ( $port.servicePort | default $port.containerPort | toString ) -}}
    {{- $servicePortList = mustAppend $servicePortList $checkRepeatingServicePort }}
- name: {{ required "\n\nError --> each defined k8s service port must have a name" $port.name }}
  port: {{ $port.servicePort | default $port.containerPort }}
  protocol: {{ $port.containerProtocol | default "TCP" }}
  targetPort: {{ required "\n\nError --> each defined k8s service must have a defined containerPort" $port.containerPort }}
  {{- end -}}
{{- end -}}
