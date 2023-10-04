{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-core.managerServiceAccountName" -}}
{{- if .Values.serviceAccounts.manager.create }}
{{- default (printf "%s-%s" (include "cluster-api-core.fullname" .) "manager" | trunc 63 | trimSuffix "-") .Values.serviceAccounts.manager.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.manager.name }}
{{- end }}
{{- end }}