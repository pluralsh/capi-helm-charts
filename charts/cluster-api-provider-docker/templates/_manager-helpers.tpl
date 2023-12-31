{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-docker.managerServiceAccountName" -}}
{{- if .Values.serviceAccounts.manager.create }}
{{- default (printf "%s-%s" (include "cluster-api-provider-docker.fullname" .) "manager" | trunc 63 | trimSuffix "-") .Values.serviceAccounts.manager.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.manager.name }}
{{- end }}
{{- end }}