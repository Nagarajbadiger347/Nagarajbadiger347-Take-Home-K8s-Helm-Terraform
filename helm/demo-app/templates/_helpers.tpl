{{/* Chart name */}}
{{- define "demo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Full resource name */}}
{{- define "demo-app.fullname" -}}
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

{{/* Chart label */}}
{{- define "demo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "demo-app.labels" -}}
helm.sh/chart: {{ include "demo-app.chart" . }}
{{ include "demo-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels */}}
{{- define "demo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Service account name */}}
{{- define "demo-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "demo-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* MongoDB connection URI */}}
{{- define "demo-app.mongoUri" -}}
{{- $username := .Values.mongodb.auth.username -}}
{{- $host := .Values.mongodb.host -}}
{{- $port := .Values.mongodb.port -}}
{{- $database := .Values.mongodb.database -}}
{{- $authSource := .Values.mongodb.database -}}
{{- printf "mongodb://%s:$(MONGO_PASSWORD)@%s:%v/%s?authSource=%s" $username $host $port $database $authSource -}}
{{- end }}
