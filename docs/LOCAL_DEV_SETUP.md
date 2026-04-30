<!-- Copyright (c) 2024-2026 Jasper Ford and anubisland contributors -->
<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# Project NEXUS - Local Development Setup

This guide walks a new developer through cloning the repository and getting the full stack running locally via Docker Compose in under 10 minutes.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Docker Desktop | 4.x+ | Windows/macOS - includes Compose V2 |
| Docker Engine + Compose plugin | 24+ | Linux alternative |
| Git | any | For cloning the repo |

No local PHP, Node.js, or database installation is required. Everything runs inside containers.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/anubisland/nexus-v1.git
cd nexus-v1
```

### 2. Copy the Docker environment file

```bash
cp .env.docker.example .env.docker
```

Edit `.env.docker` and set the database passwords at minimum:

```dotenv
DB_PASS=your_dev_password
DB_ROOT_PASSWORD=your_root_password
```

All other values have working defaults for local development. Optional API keys (Pusher, OpenAI, Google Maps, Sentry) can be left empty - features that depend on them will be disabled.

**Important:** Use `.env.docker` for Docker Compose. The `.env` file is only used for XAMPP/local PHP outside Docker. Do not confuse the two.

### 3. Start all services

```bash
docker compose up -d
```

First run pulls and builds all images - this can take 5-10 minutes. Subsequent starts are fast.

### 4. Install PHP dependencies

```bash
docker compose exec app composer install
```

`vendor/` lives on a named Docker volume (`nexus-vendor`). On Windows, bind-mounting vendor into NTFS is extremely slow due to filesystem translation overhead. The named volume uses the Docker Linux filesystem and is orders of magnitude faster.

### 5. Run database migrations

```bash
docker compose exec app php artisan migrate
```

### 6. Open the app

| Service | URL |
|---------|-----|
| React Frontend (Vite) | http://localhost:5173 |
| PHP API (Apache) | http://localhost:8090 |
| Sales / Marketing Site | http://localhost:3001 |
| Meilisearch Dashboard | http://localhost:7700 |
| phpMyAdmin (optional) | http://localhost:8091 |

---

## All Services

| Container | Image | Purpose | Port | Health Check |
|-----------|-------|---------|------|--------------|
| nexus-php-app | PHP 8.2 + Apache (custom) | Laravel/PHP backend API | 8090 | `curl /health.php` |
| nexus-php-db | MariaDB 10.11 | Primary database | internal | `healthcheck.sh --innodb_initialized` |
| nexus-php-redis | Redis 7 Alpine | Sessions, cache, queues | internal | `redis-cli ping` |
| nexus-meilisearch | Meilisearch v1.7 | Full-text + semantic search | 7700 | `curl :7700/health` |
| nexus-react-dev | Node 20 Alpine (custom) | React frontend Vite dev server | 5173 | depends on app |
| nexus-queue-worker | PHP 8.2 (same as app) | Laravel queue worker (Redis) | none | - |
| nexus-sales-site | nginx (custom) | Marketing/landing page | 3001 | `wget /` |
| nexus-phpmyadmin | phpMyAdmin (profile: tools) | DB admin UI | 8091 | - |

**Startup dependency order:** `db`, `redis`, and `meilisearch` must report **healthy** before `app` and `queue` start. Docker Compose enforces this automatically via `condition: service_healthy`.

### Starting phpMyAdmin (optional)

```bash
docker compose --profile tools up -d
```

---

## Real-time Notifications (Pusher)

The stack uses **Pusher** as an external managed service for real-time WebSocket connections. There is no self-hosted Soketi container in the development stack.

To enable real-time features locally, create a free account at https://pusher.com/ and add your credentials to `.env.docker`:

```dotenv
PUSHER_APP_KEY=your_app_key
PUSHER_APP_SECRET=your_app_secret
PUSHER_APP_ID=your_app_id
PUSHER_APP_CLUSTER=eu
```

If left empty, the app runs but real-time push notifications will be disabled.

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_PASS` | Yes | `change_me` | MariaDB nexus user password |
| `DB_ROOT_PASSWORD` | Yes | `change_me` | MariaDB root password |
| `DB_NAME` | No | `nexus` | Database name |
| `APP_ENV` | No | `development` | Laravel environment |
| `APP_DEBUG` | No | `true` | Enable debug output |
| `JWT_SECRET` | No | dev default | JWT signing secret - change in staging/prod |
| `APP_KEY` | No | dev default | Laravel app key - change in staging/prod |
| `PUSHER_APP_KEY` | No | empty | Pusher API key (real-time features) |
| `OPENAI_API_KEY` | No | empty | OpenAI API key (AI features) |
| `GOOGLE_MAPS_API_KEY` | No | empty | Google Maps Places + Geocoding |
| `MEILISEARCH_KEY` | No | empty | Meilisearch master key |
| `SENTRY_DSN_PHP` | No | empty | Sentry error tracking (PHP backend) |
| `SENTRY_DSN_REACT` | No | empty | Sentry error tracking (React frontend) |

Generate secrets for staging/production:

```bash
openssl rand -hex 32      # JWT_SECRET, APP_KEY, CRON_KEY
openssl rand -base64 32   # EMAIL_ENCRYPTION_KEY
```

Never commit `.env.docker` - it is gitignored.

---

## Common Commands

```bash
# Start all services
docker compose up -d

# Start including phpMyAdmin
docker compose --profile tools up -d

# View logs
docker compose logs -f app

# Shell into PHP container
docker compose exec app bash

# Laravel artisan
docker compose exec app php artisan migrate
docker compose exec app php artisan migrate:fresh --seed
docker compose exec app php artisan cache:clear
docker compose exec app php artisan route:list

# Heavy artisan commands that need more than 1G memory
docker compose exec app php -d memory_limit=-1 artisan scout:import "App\Models\Listing"

# PHP tests
docker compose exec app vendor/bin/phpunit --testsuite=Unit

# Frontend tests
docker compose exec frontend npm test -- --run

# TypeScript type check
docker compose exec frontend npx tsc --noEmit

# Stop all services
docker compose down

# Full reset (removes all data volumes - deletes database data)
docker compose down -v
```

### Make shortcuts

```bash
make dev       # docker compose up -d
make test      # PHPUnit + React tests
make lint      # TypeScript check
make build     # build React frontend for production
```

---

## Troubleshooting

### Services fail healthcheck on first run

MariaDB can take 30-60 seconds to initialize. Check with:

```bash
docker compose ps
docker compose logs db
```

Wait until `nexus-php-db` shows `(healthy)` before investigating other failures.

### Permission denied on storage or uploads

```bash
docker compose exec app chown -R www-data:www-data storage bootstrap/cache httpdocs/uploads uploads
docker compose exec app chmod -R 775 storage bootstrap/cache httpdocs/uploads uploads
```

### Vendor directory empty or autoload errors

```bash
docker compose exec app composer install
```

### `docker-compose` vs `docker compose`

This project uses **Compose V2** (`docker compose`, no hyphen). Upgrade Docker Desktop if you only have the V1 `docker-compose` binary.

### Windows: line ending issues

If scripts fail with `/bin/bash^M: bad interpreter`:

```bash
git config --global core.autocrlf false
git rm --cached -r .
git reset --hard
```

---

## First-time Developer Checklist

- [ ] Docker Desktop installed and running
- [ ] Repository cloned from `https://github.com/anubisland/nexus-v1`
- [ ] `.env.docker` created from `.env.docker.example` with real DB passwords
- [ ] `docker compose up -d` - all 7 services reach running/healthy state
- [ ] `docker compose exec app composer install` - vendor populated
- [ ] `docker compose exec app php artisan migrate` - schema created
- [ ] http://localhost:5173 loads the React frontend
- [ ] http://localhost:8090/health.php returns `{"status":"healthy",...}`

---

## Related Documentation

- [Docker memory configuration](DOCKER.md)
- [Database migrations guide](MIGRATIONS.md)
- [Production deployment](DEPLOYMENT.md)
- [API reference](API_REFERENCE.md)
- [Contributing guide](../CONTRIBUTING.md)
