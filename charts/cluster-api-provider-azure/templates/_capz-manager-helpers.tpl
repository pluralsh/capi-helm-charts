{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-azure.capzManagerServiceAccountName" -}}
{{- if .Values.serviceAccounts.capzManager.create }}
{{- default (include "cluster-api-provider-azure.fullname" .) .Values.serviceAccounts.capzManager.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.capzManager.name }}
{{- end }}
{{- end }}