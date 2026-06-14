# Day 37 — Helm Templating

## Chart Directory Structure

```
mychart/
├── Chart.yaml          # chart metadata (name, version, appVersion)
├── values.yaml         # default values — what users override
├── .helmignore         # like .gitignore for chart packaging
└── templates/
    ├── deployment.yaml     # templates with {{ }} placeholders
    ├── service.yaml
    ├── serviceaccount.yaml
    ├── ingress.yaml        # disabled by default (enabled: false)
    ├── hpa.yaml            # disabled by default
    ├── httproute.yaml      # disabled by default
    ├── NOTES.txt           # text printed after helm install (also templated)
    ├── _helpers.tpl        # named templates / reusable functions
    └── tests/
        └── test-connection.yaml
```

`_helpers.tpl` — the `_` prefix tells Helm: don't render this as a manifest.
It's a library of named templates called via `include`.

---

## The Three Context Objects

Every template has access to three dot-objects:

| Object | Source | Example |
|--------|--------|---------|
| `.Values` | values.yaml + --set overrides | `.Values.replicaCount` |
| `.Chart` | Chart.yaml | `.Chart.Name`, `.Chart.AppVersion` |
| `.Release` | Runtime (helm install name) | `.Release.Name`, `.Release.Service` |

### Chart.yaml → .Chart mapping

```yaml
# Chart.yaml
name: myapp          → .Chart.Name
version: 0.1.0       → .Chart.Version
appVersion: "1.16.0" → .Chart.AppVersion
```

---

## Template Syntax Patterns

### 1. Simple value substitution
```yaml
replicas: {{ .Values.replicaCount }}
```

### 2. Nested values (dot notation)
```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### 3. `default` — fallback if value is empty
```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
# if image.tag is "" → uses Chart.AppVersion
```

### 4. Whitespace control with `-`
```yaml
{{- include "myapp.labels" . | nindent 4 }}
# {{-  trims newline BEFORE the tag
# -}}  trims newline AFTER the tag
# use when the line is purely a template tag with no surrounding text
```

### 5. `nindent` — newline + indent
```yaml
labels:
  {{- include "myapp.labels" . | nindent 4 }}
# adds a newline then indents 4 spaces
# number must match the YAML indentation level
```

### 6. `include` — call a named template
```yaml
name: {{ include "myapp.fullname" . }}
# calls the named template "myapp.fullname" defined in _helpers.tpl
# the . passes the full context (values, chart, release)
```

### 7. `if/end` — conditional block
```yaml
{{- if not .Values.autoscaling.enabled }}
replicas: {{ .Values.replicaCount }}
{{- end }}
# if autoscaling.enabled=false → replicas line is included
# if autoscaling.enabled=true  → replicas line is omitted (HPA manages it)
```

### 8. `with` — conditional + rebind context
```yaml
{{- with .Values.podAnnotations }}
annotations:
  {{- toYaml . | nindent 8 }}
{{- end }}
# if podAnnotations is empty ({}) → entire block skipped, no annotations: key
# if podAnnotations has values   → block included, . rebinds to podAnnotations
```

### 9. `toYaml` — convert map/list to YAML text
```yaml
{{- toYaml . | nindent 8 }}
# converts a Go map from values.yaml into properly formatted YAML
# then pipes to nindent for correct indentation
# used for arbitrary structures: resources, tolerations, affinity, volumes
```

### 10. Pipe `|` — chain functions
```yaml
{{ .Values.nameOverride | trunc 63 | trimSuffix "-" }}
# output of left feeds into right, like Linux pipes
```

---

## _helpers.tpl — Named Templates Explained

### `myapp.name`
```
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
```
- Uses `nameOverride` if set, else `Chart.Name`
- Truncates to 63 chars (Kubernetes DNS limit)
- Removes trailing `-` after truncation

### `myapp.fullname`
Deduplication logic:
- If `fullnameOverride` set → use it directly
- If release name already contains chart name → use release name alone (avoids `myapp-myapp`)
- Otherwise → combine `releasename-chartname`

Example:
```
release=myapp, chart=myapp  →  myapp       (deduplicated)
release=prod,  chart=myapp  →  prod-myapp
```

### `myapp.labels` vs `myapp.selectorLabels`
- `myapp.labels` — full set including `helm.sh/chart` and version — used in metadata
- `myapp.selectorLabels` — stable subset (name + instance only) — used in selectors

Why separate? Selectors must be **immutable** after creation. You don't want chart version in your selector or pods break on every upgrade.

### `myapp.serviceAccountName`
```
if serviceAccount.create = true  → use generated fullname
if serviceAccount.create = false → use "default"
```

---

## values.yaml vs Override File

### values.yaml — ships with the chart
- Written by chart author
- Contains defaults for everyone
- Located inside the chart directory

### myvalues.yaml — your overrides
- Written by you (the operator)
- Contains only what you want to change
- Located outside the chart directory
- Passed with `-f myvalues.yaml`

Helm **merges** them — your values win, everything else stays as default.

### Priority order (highest wins)
```
--set flags  >  last -f file  >  earlier -f files  >  values.yaml
```

### Multiple environment files pattern
```bash
helm install myapp ./myapp \
  -f values.yaml \         # chart defaults
  -f values-prod.yaml \    # production overrides
  --set replicaCount=5     # one-off override
```

---

## Key Commands

```bash
# Scaffold a new chart
helm create myapp

# Render templates locally (no cluster connection)
helm template myapp ./myapp

# Render with --set overrides
helm template myapp ./myapp \
  --set replicaCount=3 \
  --set service.type=NodePort \
  --set image.tag=1.25.0

# Render with override values file
helm template myapp ./myapp -f myvalues.yaml

# Inspect default values of any chart
helm show values bitnami/nginx | head -60
```

### `helm template` vs `--dry-run` vs `helm install`

| Command | Connects to cluster? | Creates release? | Use for |
|---------|---------------------|-----------------|---------|
| `helm template` | No | No | Debug templates locally |
| `helm install --dry-run` | Yes | No | Full API server validation |
| `helm install` | Yes | Yes | Actual deployment |

---

## The Helm Rendering Pipeline

```
Chart templates (*.yaml with {{ }} placeholders)
        +
values.yaml (default values)
        +
your -f overrides + --set flags
        ↓
helm template engine substitutes {{ }} blocks
        ↓
plain Kubernetes YAML
        ↓
sent to API server (on helm install)
```

---

## What Gets Skipped When Values Are Empty

These values.yaml defaults cause their template blocks to be **completely omitted**:

```yaml
podAnnotations: {}      → no annotations: key in pod spec
resources: {}           → no resources: key in container
volumes: []             → no volumes: key in pod spec
tolerations: []         → no tolerations: key
affinity: {}            → no affinity: key
ingress.enabled: false  → entire ingress.yaml renders nothing
autoscaling.enabled: false → entire hpa.yaml renders nothing
```

This keeps rendered manifests clean — only what's actually set appears.

---

## Lab: myvalues.yaml Used Today

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.25.0"

service:
  type: NodePort
  port: 80

podAnnotations:
  team: "sre"
  env: "dev"
```

Result in rendered output:
- `replicas: 2`
- `image: nginx:1.25.0`
- `type: NodePort`
- `annotations: {env: dev, team: sre}` — appeared because podAnnotations was non-empty

---

## Next: Day 38 — Chart Dependencies + Hooks
