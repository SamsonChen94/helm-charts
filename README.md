# helm-charts

Helm is a tool to deploy applications on Kubernetes. Helm charts are basically templates for such applications. This Helm chart aims to function as an abstraction for Kubernetes resources, a (mostly) universal template to deploy as many applications, in as many use cases, as possible.

# TL;DR

```
$ helm install <APPLICATION_NAME> .
```

# Prerequisites

- [Kubernetes v1.18+](https://github.com/kubernetes/kubernetes)
- [Helm v3+](https://github.com/helm/helm)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)

# Installing or Upgrading Chart with Secrets

```
$ helm secrets upgrade --install -f values.yaml -f secrets/<SECRET_FILE>.yaml <APPLICATION_NAME> .
```

# Uninstalling the chart

```
$ helm delete <APPLICATION_NAME>
```

# Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|

# TODO
- Add `kind: Deployment`
- Add `kind: StatefulSet`
- Add `kind: DaemonSet`
- Add `kind: PodSecurityPolicy`
- Add `ReadWriteMany` support
- Add `kind: StorageClass`
- (Maybe) Add `kind: ClusterRole` and `kind: ClusterRoleBinding`
- Update configuration in README.md
- Add examples in README.md
- Update `Ingress` component to use `networking.k8s.io/v1` API (for Kubernetes v1.19+)
