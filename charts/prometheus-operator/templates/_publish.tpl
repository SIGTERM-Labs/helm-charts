{{/*
Render Ingress, HTTPRoute, and/or ListenerSet for a component.

Expected dict:
  root      - the root Helm context
  component - "prometheus" or "alertmanager"
  publish   - the component's .publish values
  name      - resource name (and default Service name)
  port      - default backend port number
  labels    - YAML string of labels to apply
*/}}
{{- define "prometheus-operator.publish" -}}
{{- $root := .root }}
{{- $publish := .publish }}
{{- $name := .name }}
{{- $svcPort := .port }}
{{- $labels := .labels }}
{{- $component := index $root.Values .component }}
{{- if $publish.enabled }}
{{- if not (has $publish.type (list "ingress" "gateway")) }}
{{- fail (printf "publish.type must be \"ingress\" or \"gateway\" (got %q)" $publish.type) }}
{{- end }}
{{- if not $component.service.enabled }}
{{- fail (printf "publish.enabled is true for %s but its Service is disabled. Set service.enabled=true." $name) }}
{{- end }}
{{- end }}
{{- if and $publish.enabled (eq $publish.type "ingress") }}
{{- $annotations := deepCopy ($publish.ingress.annotations | default dict) }}
{{- if and $publish.ingress.className (not (semverCompare ">=1.18-0" $root.Capabilities.KubeVersion.GitVersion)) }}
  {{- if not (hasKey $annotations "kubernetes.io/ingress.class") }}
  {{- $_ := set $annotations "kubernetes.io/ingress.class" $publish.ingress.className }}
  {{- end }}
{{- end }}
---
{{- if semverCompare ">=1.19-0" $root.Capabilities.KubeVersion.GitVersion }}
apiVersion: networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" $root.Capabilities.KubeVersion.GitVersion }}
apiVersion: networking.k8s.io/v1beta1
{{- else }}
apiVersion: extensions/v1beta1
{{- end }}
kind: Ingress
metadata:
  name: {{ $name }}
  labels:
    {{- $labels | nindent 4 }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if and $publish.ingress.className (semverCompare ">=1.18-0" $root.Capabilities.KubeVersion.GitVersion) }}
  ingressClassName: {{ $publish.ingress.className }}
  {{- end }}
  {{- if $publish.tlsEnabled }}
  tls:
    - hosts:
      {{- range $publish.hosts }}
        - {{ .host | quote }}
      {{- end }}
      {{- if $publish.ingress.tlsSecretEnabled }}
      secretName: "{{ $publish.tlsSecretName | default (printf "%s-tls" $name) }}"
      {{- end }}
  {{- end }}
  {{- if eq $publish.ingress.ruleType "rules" }}
  rules:
    {{- range $publish.hosts }}
    {{- $paths := default (list (dict "path" "/" "pathType" "Prefix")) .paths }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range $paths }}
          - path: {{ .path }}
            {{- if and .pathType (semverCompare ">=1.18-0" $root.Capabilities.KubeVersion.GitVersion) }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              {{- if semverCompare ">=1.19-0" $root.Capabilities.KubeVersion.GitVersion }}
              service:
                name: {{ $name }}
                port:
                  number: {{ .port | default $svcPort }}
              {{- else }}
              serviceName: {{ $name }}
              servicePort: {{ .port | default $svcPort }}
              {{- end }}
          {{- end }}
    {{- end }}
  {{- else if eq $publish.ingress.ruleType "defaultBackend" }}
  defaultBackend:
    service:
      name: {{ $name }}
      port:
        number: {{ $svcPort }}
  {{- end }}
{{- end }}
{{- if and $publish.enabled (eq $publish.type "gateway") }}
{{- if not $publish.gateway.name }}
{{- fail "publish.gateway.name is required when publish.type is \"gateway\"" }}
{{- end }}
{{- $gw := $publish.gateway }}
{{- $listenerSetEnabled := and $gw.listenerSet $gw.listenerSet.enabled }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $name }}
  labels:
    {{- $labels | nindent 4 }}
  {{- with $gw.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- if $listenerSetEnabled }}
    - name: {{ $name }}
      kind: ListenerSet
      group: gateway.networking.k8s.io
    {{- else }}
    - name: {{ $gw.name }}
      namespace: {{ $gw.namespace }}
      kind: Gateway
      group: gateway.networking.k8s.io
    {{- end }}
  hostnames:
    {{- range $publish.hosts }}
    - {{ .host | quote }}
    {{- end }}
  rules:
    {{- if $gw.rules }}
    {{- toYaml $gw.rules | nindent 4 }}
    {{- else }}
    {{- range $publish.hosts }}
    {{- $paths := default (list (dict "path" "/" "pathType" "Prefix")) .paths }}
    {{- range $paths }}
    - matches:
        - path:
            type: {{ if eq .pathType "Exact" }}Exact{{ else }}PathPrefix{{ end }}
            value: {{ .path }}
      backendRefs:
        - name: {{ $name }}
          port: {{ .port | default $svcPort }}
    {{- end }}
    {{- end }}
    {{- end }}
{{- if $listenerSetEnabled }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: ListenerSet
metadata:
  name: {{ $name }}
  labels:
    {{- $labels | nindent 4 }}
  {{- with $gw.listenerSet.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRef:
    name: {{ $gw.name }}
    namespace: {{ $gw.namespace }}
    kind: Gateway
    group: gateway.networking.k8s.io
  listeners:
    {{- range $publish.hosts }}
    - name: {{ .host | replace "*" "wildcard" | replace "." "-" | lower | trunc 63 | trimSuffix "-" }}
      hostname: {{ .host }}
      {{- if $publish.tlsEnabled }}
      protocol: HTTPS
      port: 443
      tls:
        certificateRefs:
          - kind: Secret
            name: "{{ $publish.tlsSecretName | default (printf "%s-tls" $name) }}"
      {{- else }}
      protocol: HTTP
      port: 80
      {{- end }}
      allowedRoutes:
        namespaces:
          from: Same
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
