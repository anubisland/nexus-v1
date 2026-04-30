# NEXUS V1 Fork Baseline

This document records the upstream commit that serves as the starting point
for the anubisland fork. All AGPL compliance tracking, attribution, and
license change-set reviews are measured from this baseline.

## Baseline Commit

| Field       | Value                                      |
|-------------|--------------------------------------------|
| SHA         | `28421e5609f78466431f1fde6c12ec6cb772dd5a`                          |
| Branch      | `main`                                     |
| Fork date   | 2026-04-30                           |
| Upstream    | https://github.com/jasperfordesq-ai/nexus-v1 |
| Fork        | https://github.com/anubisland/nexus-v1     |

## Purpose

The Hyper-Local Community Platform (Project NEXUS) is being built on top of
this AGPL-3.0 licensed codebase. The baseline SHA is used by the AGPL
compliance chain to identify which files were inherited from upstream versus
written by the anubisland team:

- [ANU-137] Attribution & copyright headers
- [ANU-138] NOTICE / CONTRIBUTORS update
- [ANU-140] AGPL source-availability compliance

## How to Verify

```bash
# Confirm baseline commit is present in the fork
git log --oneline 28421e5609f78466431f1fde6c12ec6cb772dd5a

# Show diff from baseline to current HEAD
git log --oneline 28421e5609f78466431f1fde6c12ec6cb772dd5a..HEAD

# Show all files changed since baseline
git diff --name-only 28421e5609f78466431f1fde6c12ec6cb772dd5a HEAD
```
