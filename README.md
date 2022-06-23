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
| [`services`](#services-configurations) | Optional. Kubernetes service configuration responsible for Kubernetes internal network traffic. | dict |
| [`ingress`](#ingress-configurations) | Optional. Creates a provider dependent Kubernetes [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). | dict |
| `resources` | Optional. The [resource allocation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for the workload. | dict |
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
