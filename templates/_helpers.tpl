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
{{- end }}

{{/*
  Selector labels. Meant to be used in spec.selector in many Kubernetes
  resources. Differs from basic labels due to selector labels being immutable.
*/}}
{{- define "selectorLabels" -}}
app: {{ template "fullname" . }}
{{- end }}
