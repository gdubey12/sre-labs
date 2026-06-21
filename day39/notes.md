# Day 39 — Writing a Helm Chart From Scratch (No Generator)

## Goal

Build a chart by hand, file by file, instead of using `helm create`, to
understand every piece without scaffolding doing it for you. Chart deploys an
nginx-based web app with ConfigMap-driven configuration.

---

## The Three Core Files — Mental Model

```
Chart.yaml     →  WHO is this chart (identity/metadata)
values.yaml    →  WHAT can be configured (the knobs)
_helpers.tpl   →  HOW common logic is reused (the functions)
```

### Chart.yaml — Identity
Pure metadata, no templating logic. Read once when Helm loads the chart,
exposed as `.Chart.X` inside every template.

```yaml
apiVersion: v2
name: webapp
description: A custom Helm chart for an nginx-based web app with ConfigMap-driven config
type: application
version: 0.1.0
appVersion: "1.25.0"
```

| Chart.yaml field | Available in templates as |
|------------------|---------------------------|
| `name: webapp` | `.Chart.Name` |
| `version: 0.1.0` | `.Chart.Version` |
| `appVersion: "1.25.0"` | `.Chart.AppVersion` |

### values.yaml — Configuration surface
Every key becomes accessible as `.Values.X`. Design this file by thinking
about what an *operator* should be able to change without touching templates.

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.25.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

# Custom application config — gets mounted via ConfigMap
appConfig:
  environment: "dev"
  logLevel: "info"
  maxConnections: 100

nameOverride: ""
fullnameOverride: ""

resources: {}
nodeSelector: {}
tolerations: []
affinity: {}
```

The `appConfig` block is not a generic Helm convention — it's something
designed specifically for this app. This is the chart-author mindset: define
your own configuration surface based on what your app actually needs.

### _helpers.tpl — Reusable logic
Renders nothing itself (Helm skips files prefixed `_`). Defines named
functions called via `include` from other templates — avoids repeating the
same name/label logic in every resource file.

```
{{/*
Expand the name of the chart.
*/}}
{{- define "webapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "webapp.fullname" -}}
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

{{/*
Common labels
*/}}
{{- define "webapp.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{ include "webapp.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "webapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Deliberately simpler than the `helm create` generated version — no
`serviceAccountName` helper since this chart doesn't create a ServiceAccount.
Keep helpers scoped to what the chart actually needs.

### How the three files connect — trace example

```yaml
# deployment.yaml
name: {{ include "webapp.fullname" . }}
```

Resolution chain:
```
1. Helm calls "webapp.fullname" from _helpers.tpl
2. Reads .Values.fullnameOverride (values.yaml) → empty
3. Falls through to .Chart.Name (Chart.yaml) → "webapp"
4. Combines with .Release.Name (e.g. "webapp") → deduplicated → "webapp"
5. Returns final resolved name
```

---

## Resource Templates Written

### configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "webapp.fullname" . }}-config
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
data:
  environment: {{ .Values.appConfig.environment | quote }}
  logLevel: {{ .Values.appConfig.logLevel | quote }}
  maxConnections: {{ .Values.appConfig.maxConnections | quote }}
```

Key point: `| quote` is required because ConfigMap `data` values must be
strings. `maxConnections: 100` (a number in values.yaml) would fail without
`quote` forcing it to `"100"`.

Name uses `-config` suffix to avoid colliding with the Deployment name (both
would otherwise resolve to the same `webapp.fullname`).

### deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "webapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "webapp.labels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          envFrom:
            - configMapRef:
                name: {{ include "webapp.fullname" . }}-config
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

Key line — how the ConfigMap reaches the container:
```yaml
envFrom:
  - configMapRef:
      name: {{ include "webapp.fullname" . }}-config
```
`envFrom` + `configMapRef` injects EVERY key in the ConfigMap's `data` block
as environment variables automatically — no need to list each one
individually (unlike `env: - name: X valueFrom: configMapKeyRef:`).

### service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "webapp.selectorLabels" . | nindent 4 }}
```

Best practice: `targetPort: http` matches `name: http` on the container port
in the Deployment. Kubernetes resolves named ports by string, not just
number — more maintainable if the port number ever changes (only update it
in one place).

---

## Verification Steps Used

```bash
# Render locally first — catches syntax errors before touching the cluster
helm template webapp .

# Install
helm install webapp . --namespace day39-demo --create-namespace

# Verify resources
kubectl get all -n day39-demo

# Prove ConfigMap → envFrom → container env var chain works end to end
export POD_NAME=$(kubectl get pods -n day39-demo -l app.kubernetes.io/name=webapp -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n day39-demo $POD_NAME -- env | grep -E "environment|logLevel|maxConnections"
```

Result confirmed the full chain:
```
values.yaml (appConfig.environment: "dev")
        ↓
configmap.yaml renders data.environment: "dev"
        ↓
deployment.yaml envFrom → configMapRef: webapp-config
        ↓
container env var: environment=dev   (verified live inside running pod)
```

---

## Key Lesson: ConfigMap Changes Do NOT Restart Pods

### What happened

```bash
helm upgrade webapp . --set appConfig.environment=production --set appConfig.logLevel=debug
```
Result: `REVISION: 2`, ConfigMap object updated correctly in Kubernetes — but
the running pod still showed OLD values (`dev`/`info`) when checked via
`kubectl exec ... env`.

### Why

```
helm upgrade → ConfigMap object updated (new data: production/debug)
            → Deployment's pod template spec did NOT change
            → Kubernetes sees no diff in the Deployment
            → existing pod is NOT restarted
            → old pod still has OLD env vars baked in from when it started
```

Environment variables from `envFrom`/`configMapRef` are injected **once**, at
container start. Updating the ConfigMap afterward does not push new values
into an already-running container — this is standard Kubernetes behavior, not
a bug in the chart.

### Manual fix used

```bash
kubectl rollout restart deployment/webapp -n day39-demo
kubectl rollout status deployment/webapp -n day39-demo
```

After restart, `kubectl exec ... env` correctly showed
`environment=production`, `logLevel=debug`.

### Verifying the ConfigMap itself (before restart) to confirm Helm's part worked

```bash
kubectl get configmap webapp-config -n day39-demo -o yaml
```
Showed `environment: production`, `logLevel: debug` correctly — proving the
gap was purely on the Kubernetes pod-restart side, not a Helm/template issue.

---

## STRETCH TASK (saved for later) — Checksum Annotation Pattern

Industry-standard fix to make ConfigMap changes trigger automatic rollouts,
without needing a manual `kubectl rollout restart` every time.

### The pattern

Add to `deployment.yaml`, inside `spec.template.metadata.annotations`:

```yaml
spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

### How it works

```
1. Renders the configmap.yaml template content as a string
2. Computes a SHA256 hash of that rendered content
3. Stores the hash as a pod annotation
4. When ConfigMap content changes → hash changes → pod template spec changes
5. Kubernetes sees a real diff in the Deployment → triggers a genuine rollout
6. New pods start fresh, picking up the new ConfigMap values automatically
```

This is the standard way production charts solve the "ConfigMap doesn't
restart pods" problem — avoids needing operators to remember to manually
restart deployments after every config change.

**To implement later:** add the annotation block above to
`day39/webapp/templates/deployment.yaml`, then test by changing
`appConfig.logLevel` via `--set` on `helm upgrade` and confirming pods roll
automatically without a manual `kubectl rollout restart`.

---

## Cleanup

```bash
helm uninstall webapp -n day39-demo
kubectl delete namespace day39-demo
```

---

## Next: Day 40 — Helm Project (multi-tier app using a custom chart)
