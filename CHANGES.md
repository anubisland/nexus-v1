# CHANGES from NEXUS V1 Baseline

This file documents all modifications made to the NEXUS V1 codebase as part
of the Anubisland fork, in compliance with AGPL-3.0 §5(a).

## Baseline

| Field       | Value                                                        |
|-------------|--------------------------------------------------------------|
| Upstream    | <https://github.com/jasperfordesq-ai/nexus-v1>              |
| Baseline SHA| `28421e5609f78466431f1fde6c12ec6cb772dd5a`                   |
| Fork date   | 2026-04-30                                                   |
| License     | AGPL-3.0-or-later                                            |

## Changes

### 2026-04-30 — Fork initialization

- **`BASELINE.md`** — Created. Records the upstream baseline commit SHA and
  verification instructions. (commit `ebbf507e9`)

### 2026-04-30 — Documentation drift fixes

- **`docs/LOCAL_DEV_SETUP.md`** — Created. Full Docker-based local
  development setup guide. (commit `686e79a93`)
- **`docs/DOCKER.md`** — Updated to align with current Docker Compose
  configuration.
- **`CONTRIBUTING.md`** — Minor updates.
- **`.gitignore`** — Added entries for fork-specific ignores.

### 2026-04-30 — Rebrand: NEXUS → Anubisland

- **`httpdocs/assets/img/logos/nexus_icon.png`** — Removed upstream NEXUS logo.
- **`httpdocs/assets/img/logos/nexus_icon.webp`** — Removed upstream NEXUS logo.
- **`httpdocs/manifest.json`** — Replaced NEXUS branding with Anubisland.
- **`react-frontend/index.html`** — Updated title and metadata.
- **`react-frontend/public/manifest.json`** — Updated app name and branding.
- **`react-frontend/src/components/layout/Footer.tsx`** — Updated footer branding.
- **`react-frontend/src/components/layout/Layout.tsx`** — Updated layout branding.
- **`react-frontend/src/pages/public/AboutPage.tsx`** — Added Anubisland about content.
  (commit `0570a6f33`)

### 2026-04-30 — User documentation

- **`docs/USER_GUIDE.md`** — Created first-time-use guide (English).
- **`docs/USER_GUIDE_AR.md`** — Created first-time-use guide (Arabic).
- **`README.md`** — Updated with fork-specific information.
  (commit `bfd317d1a`)
