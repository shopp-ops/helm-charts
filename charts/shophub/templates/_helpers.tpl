{{/*
Cluster name — used by CNPG and referenced in port-forward commands.
Must match the service name pattern: <clusterName>-rw
*/}}
{{- define "shophub.clusterName" -}}
{{- .Values.database.clusterName }}
{{- end }}

{{- define "shophub.credentialsSecret" -}}
{{- printf "%s-credentials" .Values.database.clusterName }}
{{- end }}
