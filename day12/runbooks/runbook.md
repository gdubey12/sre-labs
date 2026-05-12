# Runbook — CI/CD Pipeline Advanced (Matrix Builds, Caching, Notifications)

## Symptom: PR stuck — required check never reports

**Cause:** Matrix builds changed job names. Branch protection rule expects old job name.

**Diagnosis:**
- Go to repo → Settings → Rules → Rulesets
- Check "Status checks that are required"
- Compare required check names vs actual job names in Actions tab

**Fix:**
1. Add a `tests-complete` summary job to workflow:
```yaml
tests-complete:
  name: tests-complete
  runs-on: ubuntu-latest
  needs: test
  steps:
    - run: echo "All matrix tests passed"
```
2. Update branch protection ruleset — remove old check name, add `tests-complete`

---

## Symptom: Pipeline slow — pip reinstalling every run

**Cause:** No caching configured, or cache key mismatch.

**Fix:** Add cache step BEFORE install dependencies:
```yaml
- name: Cache pip dependencies
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-${{ matrix.python-version }}-
```

**Verify cache hit:** In Actions run log, look for:
```
Cache restored successfully
```
vs
```
Cache not found for input keys
```

---

## Symptom: Notify on Failure not firing

**Cause:** `needs:` list incomplete — job doesn't watch the right upstream jobs.

**Check:** Verify `notify-on-failure` has:
```yaml
needs: [tests-complete, build, security-scan]
if: failure()
```

**Test:** Intentionally break a test assertion, push, watch webhook.site for incoming POST.

---

## Symptom: Wrong image running in production

**Cause:** Pulled `latest` instead of specific SHA tag.

**Fix:** Always deploy with SHA tag:
```bash
docker pull gaurav0524/sre-cicd-app:<commit-sha>
docker run gaurav0524/sre-cicd-app:<commit-sha>
```

**Find SHA from GitHub:** Actions → workflow run → top of page shows commit SHA.

---

## Adding a New Python Version to Matrix

Edit `.github/workflows/ci.yml`:
```yaml
strategy:
  matrix:
    python-version: ['3.10', '3.11', '3.12', '3.13']  # add here
```

No other changes needed — `tests-complete` gate handles it automatically.

---

## Replacing webhook.site with Slack

Replace the curl command in `notify-on-failure`:
```yaml
- name: Send Slack notification
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H "Content-Type: application/json" \
      -d '{
        "text": "Pipeline FAILED in ${{ github.repository }} on ${{ github.ref_name }}",
        "attachments": [{
          "color": "danger",
          "text": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
        }]
      }'
```

Store Slack webhook URL as a GitHub secret: `SLACK_WEBHOOK_URL`.
