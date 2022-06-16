# helm-charts

Helm is a tool to deploy applications on Kubernetes. Helm charts are basically templates for such applications. This Helm chart aims to function as an abstraction for Kubernetes resources, a (mostly) universal template to deploy as many applications, in as many use cases, as possible.

## TL;DR

```
$ helm repo add helm-charts https://samsonchen94.github.io/helm-charts
$ helm upgrade --install --namespace <NAMESPACE> <APPLICATION_NAME> helm-charts/helm-charts
```

## Prerequisites

- [Kubernetes v1.19+](https://github.com/kubernetes/kubernetes)
- [Helm v3+](https://github.com/helm/helm)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [Helm Unit Test Plugin](https://github.com/vbehar/helm3-unittest)

# Usage

## Installing or Upgrading Chart with Secrets

```
$ helm secrets upgrade \
  --install \
  -f values.yaml \
  -f ./helm-secrets/example-environment/<SECRET_FILE>.yaml \
  --namespace <NAMESPACE> \
  <APPLICATION_NAME> .
```

## Uninstalling the chart

```
$ helm delete --namespace <NAMESPACE> <APPLICATION_NAME>
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|

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
3. Run lint test
```
$ helm lint -f values.yaml .
```
4. Run unit test
```
$ helm unittest .
```
5. Modify helm secrets
```
$ helm secrets edit .helm-secrets/<DIR_WITH_SOPS_YAML>/<ENCRYPTED_FILE>
```
6. View helm secrets
```
$ helm secrets view .helm-secrets/<DIR_WITH_SOPS_YAML>/<ENCRYPTED_FILE>
```
7. Encrypt new secret file
```
$ helm secrets enc ./helm-secrets/<DIR_WITH_SOPS_YAML>/<UNENCRYPTED_FILE>
```
8. Turn encrypted secret file to plain text
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
- Add `kind: CronJob`
- Add `kind: StatefulSet`
- Add `kind: DaemonSet`
