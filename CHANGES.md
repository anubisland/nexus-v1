# CHANGES.md — Anubisland Fork of Project NEXUS

This file documents all modifications made to the upstream Project NEXUS codebase
by Anubisland, as required by the GNU Affero General Public License version 3
(AGPL-3.0-or-later), Section 5 ("Conveying Modified Source Versions").

## Fork Information

| Field        | Value                                                        |
|--------------|--------------------------------------------------------------|
| Upstream     | https://github.com/jasperfordesq-ai/nexus-v1                 |
| Fork         | https://github.com/anubisland/nexus-v1                       |
| Baseline SHA | `28421e5609f78466431f1fde6c12ec6cb772dd5a`                   |
| Fork date    | 2026-04-30                                                   |
| License      | AGPL-3.0-or-later (unchanged from upstream)                  |

The baseline SHA marks the exact upstream commit from which this fork diverges.
All AGPL compliance, attribution, and change tracking is measured from this point.

---

## Changes Since Baseline

### 2026-04-30 — Commit ebbf507e9607

**docs: add BASELINE.md recording fork starting commit**

Records the upstream commit SHA (`28421e5609f78466431f1fde6c12ec6cb772dd5a`) as the
compliance baseline for all AGPL attribution work.

Files added:
- `BASELINE.md`

---

### 2026-04-30 — Commit 686e79a9350b

**docs: add LOCAL_DEV_SETUP.md and fix documentation drift**

- Added `docs/LOCAL_DEV_SETUP.md` covering local Docker-based development setup,
  environment configuration, service ports, real-time/Pusher setup, and
  first-time developer checklist.
- Updated `docs/DOCKER.md` to reflect current resource limits
  (memory_limit 512M->1G, upload/post limits, execution time, container limits).
- Updated `CONTRIBUTING.md`: replaced upstream repository URLs
  with fork URLs (anubisland/nexus-v1) in 2 occurrences.
- Updated `.gitignore` allowlist to untrack `docs/LOCAL_DEV_SETUP.md`.

Files added:
- `docs/LOCAL_DEV_SETUP.md`

Files modified:
- `CONTRIBUTING.md`
- `docs/DOCKER.md`
- `.gitignore`

---

### 2026-04-30 — Commit 2375bc3cc380

**feat(compliance): add AGPL-3.0 attribution notices to footer and about page (ANU-140)**

Added mandatory AGPL Section 7(b) attribution notices to user-facing pages:

- Footer component: Expanded "Project NEXUS" link to full "Built on Project NEXUS
  by Jasper Ford" text; added "Source Code" link to anubisland/nexus-v1 fork to
  satisfy the AGPL network-use source-offer requirement.
- AuthLayout footer: Added "Source Code" link to anubisland/nexus-v1 fork so
  authentication pages also satisfy the AGPL source-offer requirement.
- AboutPage: Added "Powered by Project NEXUS — Created by Jasper Ford — Licensed
  under AGPL v3" attribution statement and fork source link in the Open Source card.

All notices are placed in shared layout components to survive future redesigns.

Files modified:
- react-frontend/src/components/layout/Footer.tsx (or equivalent layout component)
- react-frontend/src/components/layout/AuthLayout.tsx (or equivalent)
- react-frontend/src/pages/AboutPage.tsx (or equivalent)

---

## How to Verify

```bash
# Confirm baseline commit is present in the fork
git log --oneline 28421e5609f78466431f1fde6c12ec6cb772dd5a

# Show all commits since baseline
git log --oneline 28421e5609f78466431f1fde6c12ec6cb772dd5a..HEAD

# Show all files changed since baseline
git diff --name-only 28421e5609f78466431f1fde6c12ec6cb772dd5a HEAD
```

---

## License

This fork is licensed under the GNU Affero General Public License version 3
(AGPL-3.0-or-later). See the LICENSE file at the repository root for the
full license text.

The source code for this fork is available at:
https://github.com/anubisland/nexus-v1
