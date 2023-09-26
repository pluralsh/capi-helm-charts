{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-azure.capzManagerServiceAccountName" -}}
{{- if .Values.serviceAccounts.capzManager.create }}
{{- default (printf "%s-%s" (include "cluster-api-provider-azure.fullname" .) capz-manager | trunc 63 | trimSuffix "-") .Values.serviceAccounts.capzManager.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.capzManager.name }}
{{- end }}
{{- end }}