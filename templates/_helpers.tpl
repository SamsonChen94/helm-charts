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
      {{ $_ := required "\n\nError: --> hpa.max is required when HPA is enabled" .hpa.max }}
      {{ $_ := required "\n\nError: --> hpa.min is required when HPA is enabled" .hpa.min }}
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

{{/*
  Check if ingress is enabled. Returns 'ingEnabled' as a boolean. Also checks
  for the following:
    1. That a Kubernetes service with NodePort type is also configured
    2. ingress.ingressConfig is empty or null, error out if so
    3. ingress.ingressConfig[].targets is emtpy or null, error out if so
    4. ingress.ingressConfig[].targets[].serviceTargets is empty or null, error out if so
    5. That the servicePort/containerPort defined in ingress is also defined with a NodePort service
  Note: Helm templates do not implement full-fledge functions. Below is an
        implementation of 'returning' a result, abide in a very weird way
  Reference: https://dastrobu.medium.com/are-helm-charts-turing-complete-46ea7a540ca2
             https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "ingEnabled" -}}
  {{- if .ing.ingress -}}
    {{- if .ing.ingress.enabled -}}
      {{- $_ := set .ingOutput "ingEnabled" true -}}
      {{- if not .ing.ingress.ingressConfig -}}
        {{- fail ( printf "\n\nError --> missing ingressConfig\n" ) -}}
      {{- end -}}
      {{- if not .ing.services -}}
        {{- fail ( printf "\n\nError --> nodePort configuration not found\n" ) -}}
      {{- else if not .ing.services.nodePort }}
        {{- fail ( printf "\n\nError --> nodePort configuration not found\n" ) -}}
      {{- end -}}
      {{- $definedServicePortList := (list) -}}
      {{- range $servicePort := .ing.services.nodePort.portConfigs -}}
        {{- $definedServicePortList = mustAppend $definedServicePortList ( $servicePort.servicePort | default $servicePort.containerPort ) -}}
      {{- end -}}
      {{- range $value := ( required "\n\nError --> missing ingressConfig in ingress settings" .ing.ingress.ingressConfig ) -}}
        {{- range $target := ( required "\n\nError --> missing targets in ingressConfig settings" $value.targets ) -}}
          {{- range $servicePort := ( required "\n\nError --> missing serviceTargets in ingressConfig target settings" $target.serviceTargets ) -}}
            {{- if not ( has $servicePort.servicePort $definedServicePortList ) -}}
              {{- fail ( printf "\n\nError --> %s port not configured in NodePort service settings\n" ( $servicePort.servicePort | toString ) ) -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := set .ingOutput "ingEnabled" false -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set .ingOutput "ingEnabled" false -}}
  {{- end -}}
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
  {{- if .config.configurations -}}
    {{- if and .config.configurations.files .config.configurations.strings -}}
      {{- $_ := set .configOutput "configFile" true }}
      {{- $_ := set .configOutput "configString" true }}
      {{- if or ( not $.config.configFiles ) ( not .config.configStrings ) -}}
        {{- fail ( printf "\n\nError --> Configuration data not found. Did you forget to add configs as an input file?\n" ) -}}
      {{- end -}}
      {{- range $configFileName := .config.configurations.files -}}
        {{- if eq ( get $.config.configFiles ( printf $configFileName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm's configuration directory" $configFileName ) -}}
        {{- end -}}
      {{- end -}}
      {{- range $configStringName := .config.configurations.strings -}}
        {{- if eq ( get $.config.configStrings ( printf $configStringName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm's configuration directory" $configStringName ) -}}
        {{- end -}}
      {{- end -}}
    {{- else if .config.configurations.files -}}
      {{- $_ := set .configOutput "configFile" true }}
      {{- $_ := set .configOutput "configString" false }}
      {{- if not .config.configFiles -}}
        {{- fail ( printf "\n\nError --> Configuration file data not found. Did you forget to add configs as an input file?\n" ) -}}
      {{- end -}}
      {{- range $configFileName := .config.configurations.files -}}
        {{- if eq ( get $.config.configFiles ( printf $configFileName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm's configuration directory" $configFileName ) -}}
        {{- end -}}
      {{- end -}}
    {{- else if .config.configurations.strings -}}
      {{- $_ := set .configOutput "configFile" false }}
      {{- $_ := set .configOutput "configString" true }}
      {{- if not .config.configStrings -}}
        {{- fail ( printf "\n\nError --> Configuration string data not found. Did you forget to add configs as an input file?\n" ) -}}
      {{- end -}}
      {{- range $configStringName := .config.configurations.strings -}}
        {{- if eq ( get $.config.configStrings ( printf $configStringName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm's configuration directory" $configStringName ) -}}
        {{- end -}}
      {{- end -}}
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
  Check if the different secrets are enabled. Returns the 'secretString' and
  'secretFile', both as booleans. Also checks if secret data declared in the
  plain text file is defined in the encrypted file.
  Note: Helm templates do not implement full-fledge functions. Below is an
        implementation of 'returning' a result, abide in a very weird way
  Reference: https://dastrobu.medium.com/are-helm-charts-turing-complete-46ea7a540ca2
             https://blog.flant.com/advanced-helm-templating/
*/}}
{{- define "secretEnabledCheck" -}}
  {{- if .secret.secrets -}}
    {{- if and .secret.secrets.files .secret.secrets.strings -}}
      {{- $_ := set .secretOutput "secretFile" true -}}
      {{- $_ := set .secretOutput "secretString" true -}}
      {{- if or ( not $.secret.secretFiles ) ( not .secret.secretStrings ) -}}
        {{- fail ( printf "\n\nError --> Secret data not found. Did you forget to add secrets as an input file?\n" ) -}}
      {{- end -}}
      {{- range $secretFileName := .secret.secrets.files -}}
        {{- if eq ( get $.secret.secretFiles ( printf $secretFileName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm-secrets" $secretFileName ) -}}
        {{- end -}}
      {{- end -}}
      {{- range $secretStringName := .secret.secrets.strings -}}
        {{- if eq ( get $.secret.secretStrings ( printf $secretStringName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm-secrets" $secretStringName ) -}}
        {{- end -}}
      {{- end -}}
    {{- else if .secret.secrets.files -}}
      {{- $_ := set .secretOutput "secretFile" true -}}
      {{- $_ := set .secretOutput "secretString" false -}}
      {{- if not .secret.secretFiles -}}
        {{- fail ( printf "\n\nError --> Secret file data not found. Did you forget to add secrets as an input file?\n" ) -}}
      {{- end -}}
      {{- range $secretFileName := .secret.secrets.files -}}
        {{- if eq ( get $.secret.secretFiles ( printf $secretFileName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm-secrets" $secretFileName ) -}}
        {{- end -}}
      {{- end -}}
    {{- else if .secret.secrets.strings -}}
      {{- $_ := set .secretOutput "secretFile" false -}}
      {{- $_ := set .secretOutput "secretString" true -}}
      {{- if not .secret.secretStrings -}}
        {{- fail ( printf "\n\nError --> Secret string data not found. Did you forget to add secrets as an input file?\n" ) -}}
      {{- end -}}
      {{- range $secretStringName := .secret.secrets.strings -}}
        {{- if eq ( get $.secret.secretStrings ( printf $secretStringName ) ) "" -}}
          {{- fail ( printf "\n\nError --> %s is not declared in helm-secrets" $secretStringName ) -}}
        {{- end -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := set .secretOutput "secretFile" false -}}
      {{- $_ := set .secretOutput "secretString" false -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set .secretOutput "secretFile" false -}}
    {{- $_ := set .secretOutput "secretString" false -}}
  {{- end -}}
{{- end -}}

{{- define "schedulingEnabled" -}}
  {{- if .scheduling.scheduling -}}
    {{- if ( and ( and .scheduling.scheduling.nodeSelector .scheduling.scheduling.taintToleration ) .scheduling.scheduling.topology ) -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" true -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" true -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" true -}}
    {{- else if ( and .scheduling.scheduling.nodeSelector .scheduling.scheduling.taintToleration ) -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" true -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" true -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" false -}}
    {{- else if ( and .scheduling.scheduling.nodeSelector .scheduling.scheduling.topology ) -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" true -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" false -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" true -}}
    {{- else if ( and .scheduling.scheduling.taintToleration .scheduling.scheduling.topology ) -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" false -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" true -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" true -}}
    {{- else if .scheduling.scheduling.nodeSelector -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" true -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" false -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" false -}}
    {{- else if .scheduling.scheduling.taintToleration -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" false -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" true -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" false -}}
    {{- else if .scheduling.scheduling.topology -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" false -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" false -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" true -}}
    {{- else -}}
      {{- $_ := set .schedulingOutput "selectorEnabled" false -}}
      {{- $_ := set .schedulingOutput "tolerationEnabled" false -}}
      {{- $_ := set .schedulingOutput "topologyEnabled" false -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set .schedulingOutput "selectorEnabled" false -}}
    {{- $_ := set .schedulingOutput "tolerationEnabled" false -}}
    {{- $_ := set .schedulingOutput "topologyEnabled" false -}}
  {{- end -}}
{{- end -}}

{{- define "probeValues" }}
failureThreshold: {{ .failureThreshold | default 3 }}
initialDelaySeconds: {{ .initialDelay | default 0 }}
periodSeconds: {{ .period | default 1 }}
successThreshold: {{ .successThreshold | default 1 }}
timeoutSeconds: {{ .timeout | default 1 }}
{{- end }}

{{- define "probe" }}
  {{- if .probe }}
    {{- if .probe.action }}
      {{- if gt ( len .probe.action ) 1 }}
        {{- fail ( printf "\n\nError --> Only one action allowed per probe. Got:\n%s" ( toYaml .probe.action ) ) }}
      {{- end }}
      {{- if not ( or ( or ( hasKey .probe.action "exec" ) ( hasKey .probe.action "httpGet" ) ) ( hasKey .probe.action "tcpSocket" ) ) }}
        {{- fail ( printf "\n\nError --> Invalid probe action. Got: %s" ( keys .probe.action | first ) ) }}
      {{- end }}
      {{- if hasKey .probe.action "httpGet" }}
        {{- if or ( empty .containerPortList ) ( not ( has .probe.action.httpGet.port .containerPortList ) ) }}
          {{- fail ( printf "\n\nError --> %s declared as HTTP probe port but not defined in 'services'. Maybe use 'services.none'?" ( .probe.action.httpGet.port | toString ) ) }}
        {{- end }}
      {{- end }}
      {{- if hasKey .probe.action "tcpSocket" }}
        {{- if or ( empty .containerPortList ) ( not ( has .probe.action.tcpSocket.port .containerPortList ) ) }}
          {{- fail ( printf "\n\nError --> %s declared as TCP probe port but not defined in 'services'. Maybe use 'services.none'?" ( .probe.action.tcpSocket.port | toString ) ) }}
        {{- end }}
      {{- end }}
{{ toYaml .probe.action }}
    {{- else }}
      {{- fail ( printf "\n\nError --> Probe execution details missing" ) }}
    {{- end }}
{{- include "probeValues" .probe }}
  {{- end }}
{{- end }}
