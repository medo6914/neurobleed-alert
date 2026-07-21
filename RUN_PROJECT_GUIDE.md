# RUN_PROJECT_GUIDE

> NeuroBleed Alert — Full-Stack Medical Monitoring System
> Updated: 2026-07-19

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Flutter Mobile](#flutter-mobile)
3. [Flutter Web](#flutter-web)
4. [FastAPI Backend](#fastapi-backend)
5. [Docker](#docker)
6. [Database](#database)

---

## Prerequisites

| Tool | Version | Check |
|---|---|---|
| Flutter SDK | >=3.0.0 | `flutter --version` |
| Dart SDK | >=3.0.0 | `dart --version` |
| Python | 3.12+ | `python --version` |
| Docker & Docker Compose | Latest | `docker --version && docker compose version` |
| Git | Latest | `git --version` |

### First-Time Setup

```bash
# 1. Clone the repository
git clone <repo-url> neurobleed-alert
cd neurobleed-alert

# 2. Copy environment file
cp .env.example .env
# Edit .env with your local configuration (defaults work for local dev)

# 3. Install Melos (monorepo tool)
dart pub global activate melos

# 4. Bootstrap monorepo
melos bootstrap
```

---

## Flutter Mobile

### First-Time Setup

```bash
cd apps/mobile_flutter

# 1. Install dependencies
flutter pub get

# 2. Generate code (json_serializable + isar_community)
dart run build_runner build --delete-conflicting-outputs

# 3. Verify no analysis errors
flutter analyze
```

### Run on Device/Emulator

```bash
# List available devices
flutter devices

# Run on specific device (replace <device-id> with actual ID)
flutter run -d <device-id>

# Run on first available device
flutter run

# Debug mode (default)
flutter run --debug

# Release mode
flutter run --release

# Profile mode (performance testing)
flutter run --profile
```

### Common Devices

```bash
# Windows Desktop
flutter run -d windows

# Android Emulator (must be running)
flutter run -d emulator-5554

# Connected Android phone
flutter run -d <device-serial>

# iOS Simulator (macOS only)
flutter run -d iPhone\ 15
```

### Hot Reload & Hot Restart

| Action | Key |
|---|---|
| **Hot Reload** | `r` (in terminal after `flutter run`) |
| **Hot Restart** | `R` (in terminal after `flutter run`) |
| **Show Widget Tree** | `w` |
| **Show Debug Paint** | `p` |
| **Open DevTools** | `d` |

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Windows
flutter build windows --release

# Clean build
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

---

## Flutter Web

### Enable Web Platform

```bash
# Enable Flutter web (one-time)
flutter config --enable-web

# Verify web is enabled
flutter devices
# Should show: Chrome, Edge, or web-server
```

### Run on Microsoft Edge

```bash
cd apps/web_flutter

# 1. Install dependencies
flutter pub get

# 2. Generate code
dart run build_runner build --delete-conflicting-outputs

# 3. Run on Microsoft Edge
flutter run -d edge

# 4. Alternative: run on Chrome
flutter run -d chrome

# 5. Run on web-server (any browser)
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000
# Then open http://localhost:5000 in any browser
```

### Localhost Address

| Mode | URL |
|---|---|
| `flutter run -d edge` | `http://localhost:54822` (random port, shown in terminal) |
| `flutter run -d web-server` | `http://localhost:5000` (custom port) |
| `flutter run -d chrome` | `http://localhost:53421` (random port) |

**Note:** The exact localhost URL is printed in the terminal after the app starts. Look for:
```
Launching lib/main.dart on Edge in web mode...
Debug service listening on ws://127.0.0.1:...
```

### Hot Reload & Hot Restart (Web)

| Action | Key/Command |
|---|---|
| **Hot Reload** | `r` in terminal |
| **Hot Restart** | `R` in terminal |
| **Open in Browser** | The browser opens automatically |
| **DevTools** | `d` in terminal |

### Build Web for Production

```bash
# Build web release
flutter build web --release

# Output goes to: build/web/
# Serve with any static file server (nginx, etc.)
```

### Web-Specific Notes

- `flutter_secure_storage` uses `flutter_secure_storage_web` on web (localStorage-based)
- `isar_community` is NOT used on web — the web app does not use Isar (it communicates via REST API)
- Firebase services work on web with appropriate configuration
- WebSocket connections work on web for real-time updates

---

## FastAPI Backend

### Create Virtual Environment

```bash
cd backend/fastapi

# Create venv
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate
```

### Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### PostgreSQL Database Setup

```bash
# Option A: Using local PostgreSQL
# Create database manually:
psql -U postgres
CREATE DATABASE neurobleed;
CREATE USER neurobleed WITH PASSWORD 'neurobleed_dev';
GRANT ALL PRIVILEGES ON DATABASE neurobleed TO neurobleed;
\q

# Option B: Using Docker (recommended for development)
docker compose -f deployment/docker/docker-compose.yml up -d postgres redis
```

### Run Alembic Migrations

```bash
# Ensure database is running (Docker or local)
# Run all pending migrations
alembic upgrade head

# Check current revision
alembic current

# View migration history
alembic history

# Rollback one step
alembic downgrade -1
```

### Seed Data

```bash
# Seed data is included in migration 3eef07e84235
# It seeds: roles (6), permissions (21), role-permission mappings
# The migration runs automatically with `alembic upgrade head`
```

### Run FastAPI Server

```bash
# Development (with hot-reload)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000

# With custom port
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

### API Documentation (Swagger)

| Feature | URL |
|---|---|
| **Swagger UI** | `http://localhost:8000/docs` |
| **ReDoc** | `http://localhost:8000/redoc` |
| **Health Check** | `http://localhost:8000/health` |

### Test REST API

```bash
# Via curl
curl http://localhost:8000/health
curl http://localhost:8000/v1/auth/login -X POST -H "Content-Type: application/json" -d '{"email":"admin@neurobleed.com","password":"admin123"}'

# Via Swagger UI: http://localhost:8000/docs
# Click "Try it out" on any endpoint
```

### Run Python Tests

```bash
# All tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Specific test file
pytest tests/test_auth.py

# Specific test
pytest tests/test_auth.py::test_login_success

# Verbose
pytest -v

# Run markers
pytest -m slow
pytest -m performance
pytest -m security
```

### Redis

```bash
# Redis runs via Docker (see Docker section)
# Default: localhost:6379
# Verify Redis is running:
redis-cli ping
# Should return: PONG
```

---

## Docker

### Docker Development

```bash
# Start all development services
docker compose -f deployment/docker/docker-compose.yml up -d

# Start specific services
docker compose -f deployment/docker/docker-compose.yml up -d postgres redis

# Start with hot-reload (uses override)
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.override.yml up -d

# View logs (all services)
docker compose -f deployment/docker/docker-compose.yml logs -f

# View logs (specific service)
docker compose -f deployment/docker/docker-compose.yml logs -f fastapi

# Rebuild a service (after code changes)
docker compose -f deployment/docker/docker-compose.yml build fastapi

# Stop all services
docker compose -f deployment/docker/docker-compose.yml down

# Stop and remove volumes (destroys database data)
docker compose -f deployment/docker/docker-compose.yml down -v
```

### Development Services

| Service | Image | Port | Description |
|---|---|---|---|
| `postgres` | postgres:16-alpine | 5432 | Primary database |
| `redis` | redis:7-alpine | 6379 | Cache & queues |
| `fastapi` | local build | 8000 | REST API |
| `ai-gateway` | local build | 8001 | AI/ML inference |

### Docker Production

```bash
# Start production stack
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.prod.yml up -d

# Run migrations in production
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.prod.yml exec fastapi alembic upgrade head

# Scale services
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.prod.yml up -d --scale fastapi=3
```

### Production Services (additional)

| Service | Port | Description |
|---|---|---|
| `nginx` | 80/443 | Reverse proxy + SSL |
| `web_flutter` | 5000 | Flutter web (pre-built) |
| `prometheus` | 9090 | Metrics collection |
| `grafana` | 3000 | Dashboards |
| `loki` | 3100 | Log aggregation |

### Docker Staging

```bash
# Start staging stack (production-like but relaxed)
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.staging.yml up -d
```

### Docker Test (CI)

```bash
# Start isolated test environment
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.test.yml up -d

# Run backend tests
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.test.yml exec fastapi pytest -v

# Clean up
docker compose -f deployment/docker/docker-compose.yml -f deployment/docker/docker-compose.test.yml down -v
```

### Useful Docker Commands

```bash
# List running containers
docker compose -f deployment/docker/docker-compose.yml ps

# Execute command inside a container
docker compose -f deployment/docker/docker-compose.yml exec fastapi bash

# Run alembic migrations via Docker
docker compose -f deployment/docker/docker-compose.yml exec fastapi alembic upgrade head

# Check container resource usage
docker stats

# View logs since last 30 minutes
docker compose -f deployment/docker/docker-compose.yml logs --since=30m

# Prune unused Docker resources
docker system prune -a
```

---

## Database

### PostgreSQL

#### Connection Details

| Property | Development Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `neurobleed` |
| User | `neurobleed` |
| Password | `neurobleed_dev` |
| URL | `postgresql+asyncpg://neurobleed:neurobleed_dev@localhost:5432/neurobleed` |

#### Managing Migrations (Alembic)

```bash
cd backend/fastapi

# Create a new migration
alembic revision --autogenerate -m "description_of_change"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Rollback to a specific revision
alembic downgrade <revision_id>

# View current state
alembic current

# View migration history
alembic history

# View raw SQL
alembic upgrade head --sql
```

#### Seed Data

```bash
# Seed data is part of migration 3eef07e84235
# To re-seed (e.g. after clearing tables):
# 1. Rollback to migration 2eef07e84234
alembic downgrade 2eef07e84234
# 2. Re-apply seed migration
alembic upgrade 3eef07e84235
```

#### Backup

```bash
# Using pg_dump (local)
pg_dump -U neurobleed -h localhost -p 5432 neurobleed > backup_$(date +%Y%m%d_%H%M%S).sql

# Using Docker
docker compose -f deployment/docker/docker-compose.yml exec postgres pg_dump -U neurobleed neurobleed > backup.sql

# With compression
pg_dump -U neurobleed -h localhost -p 5432 neurobleed | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Full backup (including roles, tablespaces)
pg_dumpall -U neurobleed -h localhost -p 5432 > full_backup.sql
```

#### Restore

```bash
# Restore from SQL file
psql -U neurobleed -h localhost -p 5432 neurobleed < backup.sql

# Restore from compressed backup
gunzip -c backup.sql.gz | psql -U neurobleed -h localhost -p 5432 neurobleed

# Using Docker
cat backup.sql | docker compose -f deployment/docker/docker-compose.yml exec -T postgres psql -U neurobleed neurobleed
```

### Redis

#### Connection Details

| Property | Development Value |
|---|---|
| Host | `localhost` |
| Port | `6379` |
| URL | `redis://localhost:6379/0` |

#### Common Commands

```bash
# Connect to Redis CLI
docker compose -f deployment/docker/docker-compose.yml exec redis redis-cli

# Monitor all commands (inside redis-cli)
MONITOR

# List keys (inside redis-cli)
KEYS *

# Get value (inside redis-cli)
GET <key>

# Flush all data (inside redis-cli)
FLUSHALL

# Check memory usage (inside redis-cli)
INFO memory
```

#### Persistence

- Redis is configured with AOF (Append-Only File) persistence in production
- Development uses default config (RDB snapshots)
- Data persists via Docker volume `redis_data`

---

## Quick Start Checklist

### First Time Running Everything

```bash
# 1. Prerequisites
flutter --version
python --version
docker --version

# 2. Environment
cp .env.example .env

# 3. Database
docker compose -f deployment/docker/docker-compose.yml up -d postgres redis

# 4. Backend
cd backend/fastapi
python -m venv venv
venv\Scripts\activate    # Windows
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 5. Flutter Mobile (new terminal)
cd apps/mobile_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run

# 6. Flutter Web (new terminal)
cd apps/web_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d edge       # or -d chrome
```

### Daily Development

```bash
# Start infrastructure
docker compose -f deployment/docker/docker-compose.yml up -d postgres redis

# Start backend (with hot-reload)
cd backend/fastapi && venv\Scripts\activate && uvicorn app.main:app --reload --port 8000

# Start Flutter
cd apps/mobile_flutter && flutter run
# or
cd apps/web_flutter && flutter run -d edge
```

---

## End-of-Phase Checklist

Before finishing any Phase, verify:

- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `pytest` — all Python tests pass
- [ ] `alembic upgrade head` — migrations up to date
- [ ] Flutter Mobile runs successfully
- [ ] Flutter Web runs on Microsoft Edge
- [ ] Backend Swagger UI loads at `http://localhost:8000/docs`
- [ ] Backend health check returns `200 OK` at `http://localhost:8000/health`
