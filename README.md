# helm-charts

Helm is a tool to deploy applications on Kubernetes. Helm charts are basically templates for such applications. This Helm chart aims to function as an abstraction for Kubernetes resources, a (mostly) universal template to deploy as many applications, in as many use cases, as possible.

## TL;DR

```
$ helm repo add helm-charts https://samsonchen94.github.io/helm-charts
$ helm repo update
$ helm secrets upgrade \
  --install \
  --namespace <NAMESPACE> \
  --set <PATH_TO_VALUES_FILE> \
  --set <PATH_TO_CONFIG_FILE> \
  --set <PATH_TO_SECRET_FILE> \
  <APPLICATION_NAME> helm-charts/helm-charts
```

## Prerequisites

- [Kubernetes v1.19+](https://github.com/kubernetes/kubernetes)
- [Kubectl v1.19+](https://kubernetes.io/docs/reference/kubectl)
- [Helm v3+](https://github.com/helm/helm)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [Helm Unit Test Plugin](https://github.com/vbehar/helm3-unittest)

# Usage

## Installing or Upgrading Chart with Secrets

```
$ helm secrets upgrade \
  --install \
  --namespace <NAMESPACE> \
  --set <PATH_TO_VALUES_FILE> \
  --set <PATH_TO_CONFIG_FILE> \
  --set <PATH_TO_SECRET_FILE> \
  <APPLICATION_NAME> helm-charts/helm-charts
```

## Uninstalling the chart

```
$ helm delete --namespace <NAMESPACE> <APPLICATION_NAME>
```

## Configuration

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `workload` | Optional. The type of Kubernetes workload to function as the main computing power. Valid types are **deployment** and **cronjob**. | string |
| `replicas` | Optional. The number of replicas for workload. Only applies to **deployment** workloads. Will be overridden if hpa.enabled is `true`. | int |
| `imageName` | Required if `workload` is defined. The docker image name and domain path to deploy to Kubernetes. | string |
| `imageTag` | Required if `workload` is defined. The docker image tag to deploy to Kubernetes. | string |
| `imagePullPolicy` | Optional. The behavior of Kubelet for downloading Docker images. [Reference](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) | string |
| `command` | Optional. Declares commands for main workload container. Commands in Kubernetes correspond to **ENTRYPOINT** in Docker. [Reference](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#notes:~:text=your%20new%20arguments.-,Note,-%3A%20The%20command) | string |
| `argument` | Optional. Declares args for main workload container. Arguments in here are the command line arguments for the command as defined in either the container image or the `command` configuration. | string |
| [`services`](#services-configurations) | Optional. Kubernetes service configuration responsible for Kubernetes internal network traffic. | dict |
| [`ingress`](#ingress-configurations) | Optional. Creates a provider dependent Kubernetes [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). | dict |
| `resources` | Optional. The [resource allocation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for the workload. | dict |
| [`liveness`](#liveness-or-readiness-or-startup-configurations) | Optional. Configuration for [liveness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command). Liveness probes are great for controlling when the pod needs a restart. | dict |
| [`readiness`](#liveness-or-readiness-or-startup-configurations) | Optional. Configuration for [readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes). Readiness probes are great for controlling when to stop sending traffic to a pod. | dict |
| [`startup`](#liveness-or-readiness-or-startup-configurations) | Optional. Configuration for [startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes). Startup probes are great for pods that have a long warm up time. Supersedes all other probes. | dict |
| [`scheduling`](#scheduling-configurations) | Optional. Controls where pods can be deploying in the Kubernetes cluster. | dict |
| [`scalingConfig`](#scalingconfig-configurations) | Optional. Scaling configuration for **deployment** workloads only. | dict |
| [`hpa`](#hpa-configurations) | Optional. Creates a [horizontal pod autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) in charge of dynamically scaling the workload according to a designated metric. | dict |
| [`cronSettings`](#cronsettings-configurations) | Required if `workload` is set to **cronjob**. Cron job configuration responsible for the running short-lived tasks. | dict |
| [`configurations`](#configurations-configurations) | Optional. Creates a [configuration map](https://kubernetes.io/docs/concepts/configuration/configmap/) Kubernetes resource responsible for injecting variables and files into the workload via environment variables and configuration mapping respectively.
| [`secrets`](#secrets-configurations) | Optional. Creates a [secret](https://kubernetes.io/docs/concepts/configuration/secret/) Kubernetes resource responsible for injecting variables and files into the workload via encoded secrets. | dict |
| [`additionalContainers`](#additionalcontainers-configurations) | Optional. Creates additional containers attached to a single Kubernetes pod. | list |

### `services` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| [`none`](#services.none-configurations) | Optional. Creates a container port for the main workload without any Kubernetes service. | dict |
| [`clusterIP`](#services.clusterip-configurations) | Optional. Creates a Kubernetes service of the **ClusterIP** type. | dict |
| [`headlessClusterIP`](#services.headlessclusterip-configurations) | Optional. Creates a [headless Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) of the **ClusterIP** type. | dict |
| [`nodePort`](#services.nodeport-configurations) | Optional. Creates a Kubernetes service of the **NodePort** type. | dict |
| [`loadBalancer`](#services.loadbalancer-configurations) | Optional. Creates a Kubernetes service of the **LoadBalancer** type. | dict |
| [`internalLoadBalancer`](#services.internalloadbalancer-configurations) | Optional. Creates a Kubernetes service of the [internal L4](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing) **LoadBalancer** type that is only internal to the VPC (using internal IP). | dict |

### `services.none` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.none` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.none.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.none.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |

### `services.clusterIP` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.clusterIP` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.clusterIP.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.clusterIP.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container and service. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |
| `portConfigs[*].servicePort` | Optional. Service port number to be used by Kubernetes service. Defaults to value in `services.clusterIP.portConfigs[*].containerPort`. | int |

### `services.headlessClusterIP` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.headlessClusterIP` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.headlessClusterIP.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.headlessClusterIP.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container and service. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |
| `portConfigs[*].servicePort` | Optional. Service port number to be used by Kubernetes service. Defaults to value in `services.headlessClusterIP.portConfigs[*].containerPort`. | int |

### `services.nodePort` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.nodePort` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.nodePort.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.nodePort.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container and service. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |
| `portConfigs[*].servicePort` | Optional. Service port number to be used by Kubernetes service. Defaults to value in `services.nodePort.portConfigs[*].containerPort`. | int |

### `services.loadBalancer` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.loadBalancer` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.loadBalancer.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.loadBalancer.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container and service. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |
| `portConfigs[*].servicePort` | Optional. Service port number to be used by Kubernetes service. Defaults to value in `services.loadBalancer.portConfigs[*].containerPort`. | int |
| `staticIP` | Optional. Manually assign a pre-reserved static IP onto the Kubernetes service. | string |
| `whitelistedIPs` | Optional. List of IP CIDR ranges to whitelist. If left empty, defaults to 0.0.0.0/0. | list |

### `services.internalLoadBalancer` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `portConfigs` | Required if `services.internalLoadBalancer` is defined. Used to declare port configurations. | list |
| `portConfigs[*].name` | Required if `services.internalLoadBalancer.portConfigs` is defined. Name of container port in Kubernetes workload. | string |
| `portConfigs[*].containerPort` | Required if `services.internalLoadBalancer.portConfigs` is defined. Container port number to be used by Kubernetes workload. | int |
| `portConfigs[*].containerProtocol` | Optional. Port protocol in container and service. Valid values are **TCP**, **UDP**, or **SCTP** (Kubernetes version > 1.20). Defaults to **TCP**. | string |
| `portConfigs[*].servicePort` | Optional. Service port number to be used by Kubernetes service. Defaults to value in `services.internalLoadBalancer.portConfigs[*].containerPort`. | int |
| `staticIP` | Optional. Manually assign a pre-reserved static IP onto the Kubernetes service. | string |
| `whitelistedIPs` | Optional. List of IP CIDR ranges to whitelist. If left empty, defaults to 0.0.0.0/0. | list |

### `ingress` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `enabled` | Optional. Switch for creating ingress resource on Kubernetes. Defaults to **false**. | boolean |
| [`ingressConfig`](#ingress.ingressconfig-configurations) | Required if `ingress` is defined and `ingress.enabled` is set to **true**. Used to declare ingress configurations. | list |

### `ingress.ingressConfig` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `reservedIPName` | Optional. Manually assign a pre-reserved static IP onto the ingress resource. | string |
| `ssl` | Optional. Option to create **managedCertificate** for each **targets[*].domainName**. Defaults to false. | boolean |
| `targets` | Required if `ingress` and `ingress.ingressConfig` are defined and `ingress.enabled` is set to **true**. Used to declare domain and Kubernetes service configurations. | list |
| `targets[*].domainName` | Required if `ingress`, `ingress.ingressConfig`, and `ingress.ingressConfig[*].targets` are defined. Also required if `ingress.enabled` is set to **true**. Declares the FQDN used for routing traffic into the ingress. <br>NOTE: This configuration is only on the Kubernetes side, DNS setup for the domain name is still required. | string |
| `targets[*].serviceTargets` | Required if `ingress`, `ingress.ingressConfig`, and `ingress.ingressConfig[*].targets` are defined. Also required if `ingress.enabled` is set to **true**. Declares the target Kubernetes service configurations and domain path configurations. | list |
| `targets[*].serviceTargets[*].domainPath` | Required if `ingress`, `ingress.ingressConfig`, `ingress.ingressConfig[*].targets`, and `ingress.ingressConfig[*].targets[*].serviceTargets` are defined. Also required if `ingress.enabled` is set to **true**. Sets the URL pathing to the service when traffic enters the ingress. Set to **/*** for all paths. | string |
| `targets[*].serviceTargets[*].servicePort` | Required if `ingress`, `ingress.ingressConfig`, `ingress.ingressConfig[*].targets`, and `ingress.ingressConfig[*].targets[*].serviceTargets` are defined. Also required if `ingress.enabled` is set to **true**. Sets the service target port in which traffic will be diverted towards. <br>NOTE: This port must correspond to a valid port configuration in `services`. | int |

### `liveness` or `readiness` or `startup` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `action` | Required if `liveness`, `readiness`, or `startup` are defined, with **only** a single `action` for each. This determines the execution type for the probe. | dict |
| `action.exec` | Optional. Mutually exclusive to `httpGet` and `tcpSocket`. `exec` configuration instructs the probe to test the container using a particular command. | dict |
| `action.exec.command` | Required if `action.exec` is defined. The bash-like command instruction for the probe to execute and determine the status of the container. | list |
| `action.httpGet` | Optional. Mutually exclusive to `exec` and `tcpSocket`. `httpGet` configuration instructs the probe to test the container using a HTTP get request and with custom header support if needed. The results of the test will be used to determine the status of the container. | dict |
| `action.httpGet.httpHeaders` | Optional. A list of custom headers for the HTTP request to be used as a test to determine the status of the container. | list |
| `action.httpGet.httpHeaders[*].name` | Required if `action.httpGet.httpHeaders` is defined. The header name to be used as a test to determine the status of the container. | string |
| `action.httpGet.httpHeaders[*].value` | Required if `action.httpGet.httpHeaders` is defined. The header value to be used as a test to determine the status of the container. | string |
| `action.httpGet.path` | Required if `action.httpGet` is defined. The path of the HTTP request the probe will use to test the status of the container. | string |
| `action.httpGet.port` | Required if `action.httpGet` is defined. The port number of the HTTP request the probe will use to test the status of the container. | int |
| `action.tcpSocket` | Optional. Mutually exclusive to `exec` and `httpGet`. `tcpSocket` configuration instructs the probe to test the container using a TCP socket. The results of the test will be used to determine the status of the container. | dict |
| `action.tcpSocket.port` | Required if `action.tcpSocket` is defined. The port number of the TCP socket the probe will use to test the status of the container. | int |
| `failureThreshold` | Optional. The number of consecutive times the probe fails the probing test to be considered to be in a failed state. Defaults to 3. | int |
| `initialDelay` | Optional. The number of seconds to wait before the probe starts its first test. Defaults to 0 seconds (immediately start testing). | int |
| `periodSeconds` | Optional. The number of seconds to wait between each probe test. Defaults to 1. | int |
| `successThreshold` | Optional. The number of consecutive times the probe succeeds the probing test to be considered to be in a running/healthy state. Defaults to 1. | int |
| `timeoutSeconds` | Optional. The number of seconds the probe test will time out. Defaults to 1. | int |

### `scheduling` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `nodeSelector` | Optional. The label key value pair to be used as a filter to specific select which node to schedule the pod to. | dict |
| `taintToleration` | Optional. List of tolerations. Tolerations are used to bypass any pre-configured node taints. Under the hood, taints in Kubernetes nodes are used to prevent some kind of workload to be deployed onto the node. [Reference](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration) | list |
| `topology` | Optional. List of topology configurations. Used to control the spread of pods across a specific topology (i.e.: zone). [Reference](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints) | list |

### `scalingConfig` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `maxSurge` | Optional. Controls how many replicas can the workload exceed the current replica count during a deployment rollout. <br>NOTE: This configuration is only applicable when `scalingConfig.type` is **RollingUpdate** | int |
| `maxUnavailable` | Optional. Controls how many existing replicas can be terminated during a deployment rollout. <br>NOTE: This configuration is only applicable when `scalingConfig.type` is **RollingUpdate** | int |
| `type` | Optional. Controls how to deploy Kubernetes deployment workloads. Can only be either [**RollingUpdate**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment) or [**Recreate**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment). | string |

### `hpa` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `enabled` | Optional. Switch for creating horizontal pod autoscaler resource on Kubernetes. Defaults to **false**. | boolean |
| `min` | Required if `hpa` is defined and `hpa.enabled` is set to **true**. Sets the minimum number of replicas the workload can scale down to. | int |
| `max` | Required if `hpa` is defined and `hpa.enabled` is set to **true**. Sets the maximum number of replicas the workload can scale up to. | int |
| `targetCPU` | Required if `hpa` is defined and `hpa.enabled` is set to **true**. The average CPU utilization target of the related workload. Once the average CPU utilization of all replicas exceeds this amount, the horizontal pod autoscaler will scale the workload replica count up. <br>NOTE: Customized scaling down behavior and additional scaling metrics are not supported (yet). | int |

### `cronSettings` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `enabled` | Optional. Switch for turning the cron job on or off while still creating the Kubernetes resource. Defaults to **true**. | boolean |
| `schedule` | Required if `cronSettings` is defined. Configures the cron schedule for the cron job Kubernetes resource. | string |
| `concurrency` | Optional. Controls the concurrency policy of the cron job. [Valid values are **Allow**, **Forbid**, and **Replace**](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/cron-job-v1/#CronJobSpec:~:text=CronJobTimeZone%20feature%20gate.-,concurrencyPolicy,-(string)). Defaults to **Allow**. | string |
| `maxFailedHistory` | Optional. Controls the number of failed job pods to retain in Kubernetes. | int |
| `maxSucceedHistory` | Optional. Controls the number of successful job jobs to retain in Kubernetes. | int |

### `configurations` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `files` | Optional. Declares the list of file names to be included into the workload via file mounting. This configuration only contains the names of the files to be mounted into workloads. The actual contents of the files must be included as a separate YAML file. <br>NOTE: File names declared here must be defined in the separate YAML file. | list
| `strings` | Optional. Declares the list of variable string names to be included into the workload via environment variable injection. This configuration only contains the names of the string variables to be injected into workloads. The actual strings in plain text must be included as a separate YAML file. <br>NOTE: String names declared here must be defined in the separate YAML file. | list

### `secrets` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `files` | Optional. Declares the list of file names to be included into the workload via encoded file mounting. This configuration only contains the names of the files to be mounted into workloads. The actual contents of the files must be included as a separate YAML file. <br>NOTE: File names declared here must be defined in the separate YAML file. | list
| `strings` | Optional. Declares the list of variable string names to be included into the workload via encoded environment variable injection. This configuration only contains the names of the string variables to be injected into workloads. The actual strings in plain text must be included as a separate YAML file. <br>NOTE: String names declared here must be defined in the separate YAML file. | list

### `additionalContainers` configurations

| Parameter | Description | Type |
| --------- | ----------- | ---- |
| `name` | Required. The name of the additional container. | string |
| `imageName` | Required. The docker image name and domain path to deploy as an additional container. | string |
| `imageTag` | Required. The docker image tag to deploy to Kubernetes. | string |
| `imagePullPolicy` | Optional. The behavior of Kubelet for downloading Docker images. [Reference](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) | string |
| `command` | Optional. Declares commands for main workload container. Commands in Kubernetes correspond to **ENTRYPOINT** in Docker. [Reference](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#notes:~:text=your%20new%20arguments.-,Note,-%3A%20The%20command) | string |
| `argument` | Optional. Declares args for main workload container. Arguments in here are the command line arguments for the command as defined in either the container image or the `command` configuration. | string |
| [`services`](#services-configurations) | Optional. Kubernetes service configuration responsible for Kubernetes internal network traffic. <br>NOTE: In the case of repeated configurations in the main container (top level `services` parameter), the configuration will be merged into the same Kubernetes service resource. | dict |
| `resources` | Optional. The [resource allocation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for the workload. | dict |
| [`configurations`](#configurations-configurations) | Optional. Creates a [configuration map](https://kubernetes.io/docs/concepts/configuration/configmap/) Kubernetes resource responsible for injecting variables and files into the workload via environment variables and configuration mapping respectively.
| [`secrets`](#secrets-configurations) | Optional. Creates a [secret](https://kubernetes.io/docs/concepts/configuration/secret/) Kubernetes resource responsible for injecting variables and files into the workload via encoded secrets. | dict |

# Development Guide

## Commit Types

1. feat (new feature for the usage of Helm)
2. fixs (bug fix for the usage of Helm)
3. docs (changes to documentation)
4. test (changes to Helm tests, unit/lint tests)
5. styl (stylistic changes)
6. rftr (refactor changes)
7. chor (non-Helm usage changes)

## Operations

1. Add helm chart repository into helm
```
$ helm repo add helm-charts https://samsonchen94.github.io/helm-charts
```
2. Update helm chart repository in helm
```
$ helm repo update helm-charts
```
3. Package a new helm chart version
```
$ helm package .
$ mv helm-charts-*.tgz docs
$ helm repo index docs --url https://samsonchen94.github.io/helm-charts
$ git add .
$ git commit -m 'chor: new release version'
$ git push origin main
```
4. Run lint test
```
$ helm lint -f values.yaml .
```
5. Run unit test
```
$ helm unittest .
```
6. Modify helm secrets
```
$ helm secrets edit .helm-secrets/<DIR_WITH_SOPS_YAML>/<ENCRYPTED_FILE>
```
7. View helm secrets
```
$ helm secrets view .helm-secrets/<DIR_WITH_SOPS_YAML>/<ENCRYPTED_FILE>
```
8. Encrypt new secret file
```
$ helm secrets enc ./helm-secrets/<DIR_WITH_SOPS_YAML>/<UNENCRYPTED_FILE>
```
9. Turn encrypted secret file to plain text
```
$ helm secrets dec ./helm-secrets/<DIR_WITH_SOPS_YAML>/<UNENCRYPTED_FILE>
```

## TODO List
- Add `kind: BackendConfig`
- Add `kind: FrontendConfig`
- Add `kind: ManagedCertificate`
- Add `kind: PersistentVolume`
- Add `kind: PersistentVolumeClaim`
- Add `kind: StorageClass`
- Configure helm-secrets
- Add `kind: Role`
- Add `kind: RoleBinding`
- Add `kind: ClusterRole`
- Add `kind: ClusterRoleBinding`
- Add `kind: ServiceAccount`
- Add `kind: StatefulSet`
- Add `kind: DaemonSet`
