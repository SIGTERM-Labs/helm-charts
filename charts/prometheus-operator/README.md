# prometheus-operator

Helm chart for Prometheus Operator custom resources. It does **not** install the operator itself — the operator and its CRDs must already be in the cluster.

Creates an optional Prometheus and Alertmanager (plus Service, RBAC, PDB, ServiceMonitor, Ingress / HTTPRoute) and any number of AlertmanagerConfig, ScrapeConfig, PrometheusRule, ServiceMonitor, and PodMonitor objects.

## Example

```yaml
prometheus:
  enabled: true
  name: k8s
  spec:
    replicas: 1
    retention: 14d
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: ceph-rbd
          resources:
            requests:
              storage: 60Gi
  serviceMonitor:
    enabled: true
  publish:
    enabled: true
    type: gateway
    hosts:
      - host: prometheus.example.com
    gateway:
      name: default-internal
      namespace: envoy-gateway-system

alertmanager:
  enabled: true
  name: main
  spec:
    replicas: 3
    alertmanagerConfigSelector:
      matchLabels:
        alertmanagerConfig: discord
    alertmanagerConfigMatcherStrategy:
      type: None
  podDisruptionBudget:
    enabled: true
    maxUnavailable: 1
  serviceMonitor:
    enabled: true
  publish:
    enabled: true
    type: gateway
    hosts:
      - host: alertmanager.example.com
    gateway:
      name: default-internal
      namespace: envoy-gateway-system

alertmanagerConfigs:
  - name: discord
    additionalLabels:
      alertmanagerConfig: discord
    spec:
      receivers:
        - name: discord-receiver
          discordConfigs:
            - apiURL:
                name: webhook-secret
                key: webhook
      route:
        receiver: discord-receiver

scrapeConfigs:
  - name: synology
    spec:
      staticConfigs:
        - labels:
            instance_name: syn1
          targets:
            - 192.168.20.100:9100

prometheusRules:
  - name: monitoring-stack-rules
    spec:
      groups:
        - name: monitoring-stack
          rules:
            - alert: PrometheusTargetDown
              expr: up == 0
              for: 10m
              labels:
                severity: critical

serviceMonitors:
  - name: kubelet
    spec:
      endpoints:
        - interval: 30s
          port: https-metrics
          scheme: https
          tlsConfig:
            insecureSkipVerify: true
      namespaceSelector:
        matchNames:
          - kube-system
      selector:
        matchLabels:
          app.kubernetes.io/name: kubelet

podMonitors: []
```

`publish` matches the generic chart: `type: ingress` renders an Ingress, `type: gateway` renders an HTTPRoute (and a ListenerSet when `gateway.listenerSet.enabled` is true). Prometheus and Alertmanager each have their own `publish` block.

AlertmanagerConfig and PrometheusRule specs often contain Go templates. Quote them or wrap them in backticks so Helm does not interpret them:

```yaml
title: '{{`{{ range .Alerts }}{{ .Annotations.title }}{{ end }}`}}'
```
