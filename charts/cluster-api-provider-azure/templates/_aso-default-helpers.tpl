{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-azure.asoDefaultServiceAccountName" -}}
{{- if .Values.serviceAccounts.asoDefault.create }}
{{- default (include "cluster-api-provider-azure.fullname" .) .Values.serviceAccounts.asoDefault.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.asoDefault.name }}
{{- end }}
{{- end }}