{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-api-provider-azure.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-api-provider-azure.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- $releaseName := ternary "capz" .Release.Name (contains .Release.Name .Chart.Name) }}
{{- if contains $name $releaseName }}
{{- $releaseName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" $releaseName $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cluster-api-provider-azure.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-api-provider-azure.labels" -}}
helm.sh/chart: {{ include "cluster-api-provider-azure.chart" . }}
{{ include "cluster-api-provider-azure.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cluster-api-provider-azure.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-api-provider-azure.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-azure.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cluster-api-provider-azure.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the azure ASO settings depending on if bootstrap credentials should be used
*/}}
{{- define "cluster-api-provider-azure.aso-credentials" -}}
{{- if .Values.bootstrapMode -}}
AZURE_CLIENT_ID: {{ .Values.asoControllerSettings.azureClientId | b64enc | quote }}
AZURE_SUBSCRIPTION_ID: {{ .Values.asoControllerSettings.azureSubscriptionId | b64enc | quote }}
AZURE_TENANT_ID: {{ .Values.asoControllerSettings.azureTenantId | b64enc | quote }}
AZURE_CLIENT_SECRET: {{ .Values.asoControllerSettings.azureClientSecret | b64enc | quote }}
{{- else -}}
AZURE_CLIENT_ID: {{ .Values.asoControllerSettings.azureClientId | b64enc | quote }}
AZURE_SUBSCRIPTION_ID: {{ .Values.asoControllerSettings.azureSubscriptionId | b64enc | quote }}
AZURE_TENANT_ID: {{ .Values.asoControllerSettings.azureTenantId | b64enc | quote }}
USE_WORKLOAD_IDENTITY_AUTH: "true"
{{- end -}}
{{- end -}}
