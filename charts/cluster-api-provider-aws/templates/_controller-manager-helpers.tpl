{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-api-provider-aws.controllerManagerServiceAccountName" -}}
{{- if .Values.serviceAccounts.controllerManager.create }}
{{- default (printf "%s-%s" (include "cluster-api-provider-aws.fullname" .) "controller-manager" | trunc 63 | trimSuffix "-") .Values.serviceAccounts.controllerManager.name }}
{{- else }}
{{- default "default" .Values.serviceAccounts.controllerManager.name }}
{{- end }}
{{- end }}