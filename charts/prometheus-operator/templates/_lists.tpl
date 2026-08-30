{{/*
Render a list of Prometheus Operator CRs with pass-through specs.

Expected dict:
  root       - the root Helm context
  items      - the list of items from values
  kind       - Kubernetes kind
  apiVersion - default apiVersion if an item does not set one
  listName   - values key, used in fail messages (e.g. "serviceMonitors")
*/}}
{{- define "prometheus-operator.monitoringList" -}}
{{- range $i, $item := .items }}
{{- if not $item.name }}
{{- fail (printf "%s[%d].name is required" $.listName $i) }}
{{- end }}
{{- if not $item.spec }}
{{- fail (printf "%s[%d].spec is required" $.listName $i) }}
{{- end }}
---
apiVersion: {{ $item.apiVersion | default $.apiVersion }}
kind: {{ $.kind }}
metadata:
  name: {{ $item.name }}
  labels:
    {{- include "prometheus-operator.labels" $.root | nindent 4 }}
    {{- with $item.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $item.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- toYaml $item.spec | nindent 2 }}
{{- end }}
{{- end }}
