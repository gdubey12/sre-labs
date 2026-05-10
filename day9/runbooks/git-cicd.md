# Runbook — Git Workflows + CI/CD

## Daily Git Workflow
```bash
git checkout main && git pull          # always start fresh
git checkout -b feature/your-thing     # create branch
# ... make changes ...
git add . && git commit -m "feat: description"
git push -u origin feature/your-thing  # open PR on GitHub
# after PR merged:
git checkout main && git pull          # sync local
git branch -d feature/your-thing      # clean up local branch
```

## Keeping Branch Up To Date (Rebase)
```bash
git checkout main && git pull
git checkout feature/your-thing
git rebase main
# if conflicts: fix files → git add . → git rebase --continue
```

## Emergency: Find Which Commit Broke Production
```bash
git bisect start
git bisect bad                         # current HEAD is broken
git bisect good <last-known-good-hash> # from CI logs or git log
# test at each step, then:
git bisect good   # or git bisect bad
# repeat until: "X is the first bad commit"
git bisect reset  # return to HEAD
git revert <bad-hash>  # undo the guilty commit
```

## Apply One Commit to Another Branch
```bash
git checkout main
git cherry-pick <commit-hash>
git push origin main  # via PR in real teams
```

## Clean Up Messy Commits Before PR
```bash
git rebase -i HEAD~N   # N = number of commits to clean
# change 'pick' to 'squash' on commits to fold in
# write one clean commit message
```

## Pipeline Failures — Where To Look
| Stage failed | Check |
|---|---|
| Run Tests | pytest output — assertion error or import error |
| Build Docker Image | Dockerfile syntax, missing COPY files |
| Security Scan | Trivy found CRITICAL CVE — update base image |
| Push to DockerHub | Check DOCKERHUB_USERNAME and DOCKERHUB_TOKEN secrets |

## Pre-commit Hook Setup
```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if grep -r "print(" --include="*.py" .; then
  echo "ERROR: debug print() found."
  exit 1
fi
exit 0
EOF
chmod +x .git/hooks/pre-commit
```
