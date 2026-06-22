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

{{/*
ServiceAccount name the API pod runs as.
Override with serviceAccount.name; defaults to <release>-api.
*/}}
{{- define "shophub.serviceAccountName" -}}
{{- .Values.serviceAccount.name | default (printf "%s-api" .Release.Name) }}
{{- end }}

{{/*
Cluster-scoped RBAC name. Includes namespace + release so multiple
ShopHub installs never collide on a single ClusterRole/Binding.
*/}}
{{- define "shophub.shopManagerRoleName" -}}
{{- printf "%s-%s-shop-manager" .Release.Namespace .Release.Name }}
{{- end }}
