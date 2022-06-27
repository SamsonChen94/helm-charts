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
{{- $schedulingArgs := dict "scheduling" .Values "schedulingOutput" (dict) }}
{{- include "schedulingEnabled" $schedulingArgs }}
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
      {{- $valuesArgs := dict "Release" .Release "Values" .Values "configArgs" $configArgs "secretArgs" $secretArgs }}
      {{- include "containerTemplate" $valuesArgs | indent 6 }}
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
      {{- $additionalContainerArgs := dict "Release" $.Release "Values" $additionalContainer "configArgs" $additionalConfigArgs "secretArgs" $additionalSecretArgs }}
      {{- include "containerTemplate" $additionalContainerArgs | indent 6 }}
      {{- if $additionalConfigArgs.configOutput.configFile }}
      {{- $additionalContainerConfigFileEnabled = true }}
      {{- end }}
      {{- if $additionalSecretArgs.secretOutput.secretFile }}
      {{- $additionalContainerSecretFileEnabled = true }}
      {{- end }}
      {{- end }}
      {{- end }}
    dnsPolicy: ClusterFirst
    {{- if $schedulingArgs.schedulingOutput.selectorEnabled }}
    nodeSelector:
      {{- toYaml $schedulingArgs.scheduling.scheduling.nodeSelector | nindent 6 }}
    {{- end }}
    restartPolicy: Always
    terminationGracePeriodSeconds: 10
    {{- if $schedulingArgs.schedulingOutput.tolerationEnabled }}
    tolerations:
      {{- toYaml $schedulingArgs.scheduling.scheduling.taintToleration | nindent 6 }}
    {{- end }}
    {{- if $schedulingArgs.schedulingOutput.topologyEnabled }}
    topologySpreadConstraints:
      {{- toYaml $schedulingArgs.scheduling.scheduling.topology | nindent 6 }}
    {{- end }}
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
