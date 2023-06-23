{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-api-provider-aws.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-api-provider-aws.fullname" -}}
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
{{- define "cluster-api-provider-aws.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-api-provider-aws.labels" -}}
helm.sh/chart: {{ include "cluster-api-provider-aws.chart" . }}
{{ include "cluster-api-provider-aws.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cluster-api-provider-aws.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-api-provider-aws.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-aws.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cluster-api-provider-aws.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the aws credentials file
*/}}
{{- define "cluster-api-provider-aws.awsCredentialsFile" -}}
[default]
aws_access_key_id = {{ .Values.managerBootstrapCredentials.AWS_ACCESS_KEY_ID }}
aws_secret_access_key = {{ .Values.managerBootstrapCredentials.AWS_SECRET_ACCESS_KEY }}
region = {{ .Values.managerBootstrapCredentials.AWS_REGION }}
{{- if .Values.managerBootstrapCredentials.AWS_SESSION_TOKEN }}
aws_session_token = {{ .Values.managerBootstrapCredentials.AWS_SESSION_TOKEN  }}
{{- end }}
{{- end -}}

{{/*
Return the b64 encoded aws credentials file depending on if bootstrap credentials should be used
*/}}
{{- define "cluster-api-provider-aws.awsCredentialsValue" -}}
{{- if .Values.bootstrapMode -}}
{{- include "cluster-api-provider-aws.awsCredentialsFile" . | b64enc | quote -}}
{{- else -}}
{{ print "Cg=="  }}
{{- end -}}
{{- end -}}
