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
  Image name and tag. Meant to be used in spec.template.spec.containers[].image
  This should handle errors as well
*/}}
{{- define "imageNameTag" -}}
  {{- if not .Values.imageName -}}
    {{- fail ( printf "\n\nError --> 'imageName' not defined\n" ) -}}
  {{- end -}}
  {{- if not .Values.imageTag -}}
    {{- fail ( printf "\n\nError --> imageTag not found, use --set in the helm command 'helm --set imageTag=\"v1.0.0\" ...'\n" ) -}}
  {{- end -}}
  image: {{ .Values.imageName }}:{{ .Values.imageTag }}
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
