---
name: workflow-analyzer
description: >
  Examines CI/CD, scripts, git hooks, and deployment workflows.
  Used by gap analysis to find workflow patterns not captured in config.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(git:*)
---

## Task

Examine package.json scripts, CI configs, Makefiles, Dockerfiles, deploy scripts, git hooks, PR templates, and workflow documentation. Map out:

1. **Dev to Production** — How does code go from local dev to production?
2. **Linting/Formatting** — What's enforced and how?
3. **Testing Stages** — What testing stages exist?
4. **External Services** — What external services does the project talk to?
5. **Manual Processes** — What manual processes could benefit from automation via agents?

## Approach

- Check for `package.json` scripts, `Makefile`, `Taskfile`, `justfile`
- Look for CI configs in `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`, `Jenkinsfile`
- Check for `Dockerfile`, `docker-compose.yml`
- Look for git hooks in `.husky/`, `.git/hooks/`
- Check for PR/issue templates in `.github/`
- Read deploy scripts or infrastructure config

## Output

Write findings to `./audit/workflows-found.md` with clear sections per workflow area.
