# Day 9 — Git + CI/CD

## Key Concepts

### Git Workflows
- Feature branch: never commit directly to main — branch → PR → merge
- Rebase: replays your commits on top of latest main — linear history, no merge commit fork
- Cherry-pick: takes one specific commit from any branch — new hash, same changes
- git bisect: binary search across commits to find which one introduced a bug
- Interactive rebase (rebase -i): squash messy WIP commits into one clean commit before PR
- Pre-commit hooks: .git/hooks/pre-commit — runs before every commit, blocks on failure

### CI/CD Pipeline
- Jobs run in order via needs: — test → build → security scan → push
- Failure cascades: if tests fail, build and scan are skipped
- if: condition on push job — only fires on merge to main, skipped on PRs
- DockerHub PAT preferred over password for CI authentication

### PR Protection Rules
- Branch rulesets: no direct push to main, required status checks
- Merge button stays greyed out until all required checks pass
- Server-side enforcement — no one can bypass it

## Commands Reference
```bash
git checkout -b feature/name        # create feature branch
git rebase main                     # rebase onto latest main
git cherry-pick <hash>              # apply one commit
git bisect start                    # start binary search
git bisect good <hash>              # mark known good commit
git bisect bad                      # mark current as bad
git bisect reset                    # end bisect session
git rebase -i HEAD~N                # interactive rebase last N commits
git log --oneline --graph --all     # visualise branch history
```

## Labs Completed
- Flask app + tests at ~/labs/day9/myapp/
- GitHub Actions pipeline: test → build → security scan → DockerHub push
- Break lab 1: failing test — pipeline failed at test stage
- Break lab 2: bad COPY filename — pipeline failed at build stage
- Feature branch PR merged via GitHub
- Rebase lab: diverged branches merged cleanly
- Cherry-pick lab: single commit applied to main
- git bisect: found guilty commit in 2 steps across 8 releases
- Interactive rebase: 3 messy commits squashed into 1
- Pre-commit hook: blocked print() from being committed
- DockerHub push automated in CI pipeline
- PR protection rules: merge button blocked on failing tests

## Repos
- github.com/gdubey12/sre-cicd-app
- DockerHub: gaurav0524/sre-cicd-app
