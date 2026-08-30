{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus-operator.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get the instance name
*/}}
{{- define "prometheus-operator.instance" -}}
{{- default .Release.Name .Values.instanceOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prometheus-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "prometheus-operator.chart" -}}
{{- printf "%s" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "prometheus-operator.labels" -}}
{{ include "prometheus-operator.selectorLabels" . }}
app.kubernetes.io/namespace: {{ .Release.Namespace }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "prometheus-operator.selectorLabels" -}}
helm.sh/chart: {{ include "prometheus-operator.chart" . }}
app.kubernetes.io/name: {{ include "prometheus-operator.name" . }}
app.kubernetes.io/instance: {{ include "prometheus-operator.instance" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* ---------- Prometheus ---------- */}}

{{- define "prometheus-operator.prometheus.name" -}}
{{- default "k8s" .Values.prometheus.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "prometheus-operator.prometheus.serviceName" -}}
{{- default (printf "prometheus-%s" (include "prometheus-operator.prometheus.name" .)) .Values.prometheus.service.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "prometheus-operator.prometheus.serviceAccountName" -}}
{{- if .Values.prometheus.serviceAccount.create }}
{{- default "prometheus" .Values.prometheus.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.prometheus.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "prometheus-operator.prometheus.labels" -}}
{{ include "prometheus-operator.labels" . }}
app.kubernetes.io/component: prometheus
prometheus: {{ include "prometheus-operator.prometheus.name" . }}
{{- end }}

{{/*
Labels the prometheus-operator sets on Prometheus pods. Used as the default
Service / PDB selector. Override with prometheus.service.selector.
*/}}
{{- define "prometheus-operator.prometheus.selectorLabels" -}}
{{- if and .Values.prometheus.service.selector (gt (len .Values.prometheus.service.selector) 0) }}
{{- toYaml .Values.prometheus.service.selector }}
{{- else -}}
app.kubernetes.io/name: prometheus
app.kubernetes.io/instance: {{ include "prometheus-operator.prometheus.name" . }}
prometheus: {{ include "prometheus-operator.prometheus.name" . }}
{{- end }}
{{- end }}

{{- define "prometheus-operator.prometheus.webPort" -}}
{{- $port := 9090 }}
{{- range .Values.prometheus.service.ports }}
{{- if eq .name "web" }}
{{- $port = .port }}
{{- end }}
{{- end }}
{{- $port }}
{{- end }}

{{/* ---------- Alertmanager ---------- */}}

{{- define "prometheus-operator.alertmanager.name" -}}
{{- default "main" .Values.alertmanager.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "prometheus-operator.alertmanager.serviceName" -}}
{{- default (printf "alertmanager-%s" (include "prometheus-operator.alertmanager.name" .)) .Values.alertmanager.service.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "prometheus-operator.alertmanager.serviceAccountName" -}}
{{- if .Values.alertmanager.serviceAccount.create }}
{{- default (printf "alertmanager-%s" (include "prometheus-operator.alertmanager.name" .)) .Values.alertmanager.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.alertmanager.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "prometheus-operator.alertmanager.labels" -}}
{{ include "prometheus-operator.labels" . }}
app.kubernetes.io/component: alert-router
alertmanager: {{ include "prometheus-operator.alertmanager.name" . }}
{{- end }}

{{/*
Labels the prometheus-operator sets on Alertmanager pods. Used as the default
Service / PDB selector. Override with alertmanager.service.selector.
*/}}
{{- define "prometheus-operator.alertmanager.selectorLabels" -}}
{{- if and .Values.alertmanager.service.selector (gt (len .Values.alertmanager.service.selector) 0) }}
{{- toYaml .Values.alertmanager.service.selector }}
{{- else -}}
app.kubernetes.io/name: alertmanager
app.kubernetes.io/instance: {{ include "prometheus-operator.alertmanager.name" . }}
alertmanager: {{ include "prometheus-operator.alertmanager.name" . }}
{{- end }}
{{- end }}

{{- define "prometheus-operator.alertmanager.webPort" -}}
{{- $port := 9093 }}
{{- range .Values.alertmanager.service.ports }}
{{- if eq .name "web" }}
{{- $port = .port }}
{{- end }}
{{- end }}
{{- $port }}
{{- end }}
