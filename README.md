# helm-charts

Helm is a tool to deploy applications on Kubernetes. Helm charts are basically templates for such applications. This Helm chart aims to function as an abstraction for Kubernetes resources, a (mostly) universal template to deploy as many applications, in as many use cases, as possible.

## TL;DR

```
$ helm upgrade --install --namespace <NAMESPACE> <APPLICATION_NAME> .
```

## Prerequisites

- [Kubernetes v1.19+](https://github.com/kubernetes/kubernetes)
- [Helm v3+](https://github.com/helm/helm)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [Helm Unit Test Plugin](https://github.com/vbehar/helm3-unittest)

# Usage

## Installing or Upgrading Chart with Secrets

```
$ helm secrets upgrade --install -f values.yaml -f secrets/<SECRET_FILE>.yaml --namespace <NAMESPACE> <APPLICATION_NAME> .
```

## Uninstalling the chart

```
$ helm delete <APPLICATION_NAME>
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

1. Running lint test
```
$ helm lint
```
2. Running unit test
```
$ helm unittest .
```

## TODO List
- Configure helm unittest
- Add `kind: Deployment`
- Add `kind: BackendConfig`
- Add `kind: FrontendConfig`
- Add `kind: Service`
- Add `kind: Ingress`
- Add `kind: ManagedCertificate`
- Add `kind: HorizontalPodAutoscaler`
- Add `kind: PersistentVolume`
- Add `kind: PersistentVolumeClaim`
- Add `kind: StorageClass`
- Configure helm-secrets
- Add `kind: Secret`
- Add `kind: Role`
- Add `kind: RoleBinding`
- Add `kind: ClusterRole`
- Add `kind: ClusterRoleBinding`
- Add `kind: ServiceAccount`
- Add `kind: CronJob`
- Add `kind: StatefulSet`
- Add `kind: DaemonSet`
