# AGENTS.md — ssmenable

Context for AI coding agents (Claude Code, Codex, opencode, Cursor, …) working in this repo.
Read this first; keep it current.

## What this is
A **legacy** (last touched 2022-07) set of Bash scripts that bootstrap the "SSM patching for
EC2" baseline for one AWS account/company: SNS topics + email subscriptions, the IAM roles and
policies that make SSM/SNS work, S3 buckets with a lifecycle rule, and a separate script that
creates the three `aws-iam-authenticator` Kubernetes roles. Interactive, run-by-hand ops
tooling — not a deployable project.

## Layout
- `ssmenable.sh` — interactive end-to-end bootstrap (prompts for a company name, then creates
  SNS topics/roles/policies/buckets via the AWS CLI).
- `create3roles.sh` — creates `k8sAdmin` / `k8sDev` / `k8sInteg` IAM roles for EKS +
  aws-iam-authenticator (trust = the current account root).
- `snspublish.json`, `trust.json`, `trust2.json`, `IAMpassrolesns.json`, `lifecycle.json` —
  IAM/trust/lifecycle policy documents consumed with `--policy-document file://…`.
- `.gitattributes` — line-ending normalization.

## Commands
No build/test/lint tooling in-repo. The scripts require an authenticated `aws` CLI and mutate a
real account — do not run them unless you intend to change AWS.

## Conventions / rules
- JSON policies live in separate `.json` files and are passed with `file://` — keep new policy
  documents in files, never inline.
- PR workflow: feature branch → PR → merge to `main`. There is no CI here.

## Gotchas
- `ssmenable.sh` `sed -i`s `IAMpassrolesns.json` in place (replaces `@replaceme@` with a role
  ARN), so re-running it mutates the tracked file — expect spurious diffs / a corrupted template.
- Several IAM lookups use hardcoded role/policy names (`SNSNotifications`, `SNSPublishPermissions`,
  `MaintenanceWindowRole`) that don't match the `${company_name}-…` names the script creates, so
  the lookups can come back empty.
- `ssmenable.sh` sets `snsnameDEV` to the `-PRD-Instances` name (copy/paste bug).
- The script subscribes a personal email endpoint to SNS; keep that address out of any new code.
- Never commit credentials, tokens, or account IDs that aren't already in the repo.
