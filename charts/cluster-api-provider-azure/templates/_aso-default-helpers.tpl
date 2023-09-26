{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-azure.asoDefaultServiceAccountName" -}}
{{- if .Values.serviceAccounts.asoDefault.create }}
{{- default (printf "%s-%s" (include "cluster-api-provider-azure.fullname" .) aso-default | trunc 63 | trimSuffix "-") .Values.serviceAccounts.asoDefault.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.asoDefault.name }}
{{- end }}
{{- end }}