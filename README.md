# caprover-app-template

A batteries-included full-stack starter for shipping real web apps on a $10/year VPS. Click **Use this template** to get started.

## What's included

| Layer | Stack |
|-------|-------|
| Backend | Express 5, better-sqlite3 (WAL mode), Server-Sent Events |
| Frontend | Vite 6, React 18, TypeScript, DaisyUI v4, Tailwind CSS v3 |
| Auth | JWT (30-day), bcrypt, OAuth (GitHub / Google / Discord) |
| State | Zustand v5 with persist middleware |
| Routing | react-router-dom v7 |
| Icons | react-feather (Feather Icons) |
| Package manager | pnpm workspaces (root + `client/`) |
| Deployment | CapRover via GitHub Actions |
| Containers | Docker multi-stage build → GHCR |

## Why CapRover on a cheap VPS?

Netlify and Vercel are great for static sites and serverless functions. This template is a different shape — a persistent, always-on server with a local SQLite database and long-lived SSE connections. That shape fits self-hosting far better than serverless platforms:

- **SQLite works** — one file, no separate database bill, WAL mode handles concurrent reads
- **SSE works** — no function timeout kills the connection
- **Costs ~$0.83–1.25/month** — vs $19–20/month for comparable paid SaaS tiers
- **No vendor lock-in** — standard Docker image, moves to any host in minutes
- **Branch previews included** — `preview.yml` brings Vercel-style ephemeral environments to your self-hosted stack

[RackNerd](https://racknerd.com) regularly runs KVM VPS deals at $10–15/year (1 vCPU, 1 GB RAM, 20 GB SSD) — enough to run CapRover plus several small apps simultaneously.

## Project structure

```
.
├── client/                  # Vite + React frontend (pnpm workspace)
│   ├── src/
│   │   ├── components/      # Navbar, AuthWrapper (route guards)
│   │   ├── routes/          # Home, Dashboard, SignIn, SignUp, Settings, AuthCallback
│   │   ├── services/        # apiClient.ts — typed fetch wrapper
│   │   └── store/           # authStore.ts — Zustand auth + theme state
│   ├── vite.config.ts       # Proxies /api → :8080 in dev
│   └── tailwind.config.js
├── routes/
│   ├── auth.mjs             # Signup, signin, OAuth, /me, /profile
│   └── sse.mjs              # GET /api/sse/stream — per-user event stream
├── middlewares/
│   ├── requireAuth.mjs
│   └── requireAdmin.mjs
├── scripts/
│   ├── scaffold.sh          # One-time CapRover app setup
│   ├── sync-secrets.sh      # Push .env.local → GitHub Secrets + CapRover
│   ├── env-crypt.sh         # GPG-encrypt .env.local for git storage
│   ├── bootstrap.sh         # Decrypt .env.local on a new machine
│   ├── localDev.mjs         # Seeds dev user, auto-generates JWT_SECRET
│   └── postinstall.mjs      # Rebuilds better-sqlite3 on Android/Termux
├── config/
│   └── admins.json          # Static admin email allowlist
├── .github/workflows/
│   ├── deploy.yml           # Push to master → build → deploy to CapRover
│   └── preview.yml          # Push to branch → ephemeral preview app
├── db.mjs                   # SQLite schema + connection singleton
├── events.mjs               # EventEmitter singleton for SSE
├── index.mjs                # Express server entry point
└── Dockerfile               # Multi-stage: client build → production server
```

## Getting started

### Prerequisites

- Node.js 20+, pnpm 9+
- [CapRover](https://caprover.com) instance (or just run locally)
- A GitHub account (for CI and GHCR)

### Local development

```bash
# 1. Clone and install
git clone https://github.com/asyncawaitpromise/caprover-app-template
cd caprover-app-template
pnpm install

# 2. Copy and fill in secrets
cp .env.example .env.local

# 3. Start backend + frontend concurrently
pnpm dev
# Backend:  http://localhost:8080
# Frontend: http://localhost:5173 (proxies /api to :8080)
```

The `dev` script uses `nodemon` for the backend and `vite` for the frontend via `concurrently`. A dev user (`dev@local`) is seeded automatically and a `JWT_SECRET` is generated if one is not set.

### First deploy

```bash
# 1. Create the CapRover app and set all env vars
bash scripts/scaffold.sh

# 2. Sync secrets to GitHub and CapRover
bash scripts/sync-secrets.sh

# 3. Push to master — GitHub Actions does the rest
git push origin master
```

### Encrypted secrets (optional)

```bash
# Encrypt .env.local so it can be committed
bash scripts/env-crypt.sh      # → .env.local.enc (committed)

# On a new machine, decrypt it
bash scripts/bootstrap.sh
```

## Environment variables

See `.env.example` for the full list. Key variables:

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | Random string, min 32 chars |
| `PORT` | Server port (default 8080) |
| `GOOGLE_CLIENT_ID` / `_SECRET` | Google OAuth app credentials |
| `GITHUB_CLIENT_ID` / `_SECRET` | GitHub OAuth app credentials |
| `DISCORD_CLIENT_ID` / `_SECRET` | Discord OAuth app credentials |
| `OAUTH_CALLBACK_BASE` | Public base URL (e.g. `https://myapp.example.com`) |
| `CAPROVER_URL` | CapRover dashboard URL |
| `CAPROVER_PASSWORD` | CapRover admin password |
| `CAPROVER_APP` | App name in CapRover |
| `CAPROVER_APP_DOMAIN` | Domain suffix for preview URLs |
| `ADMIN_USERS` | JSON array `[{"email":"you@example.com"}]` for runtime admin grants |

## GitHub Actions secrets

Set these in your repo → Settings → Secrets and variables → Actions:

| Secret | Used by |
|--------|---------|
| `JWT_SECRET` | Both workflows |
| `CAPROVER_URL` | Both workflows |
| `CAPROVER_PASSWORD` | Both workflows |
| `CAPROVER_APP_DOMAIN` | `preview.yml` (for preview URL output) |

GHCR access uses the built-in `GITHUB_TOKEN` — no extra secret needed.

## Auth

- **Email/password** — open registration by default; gate it behind `requireAdmin` middleware if you want invite-only
- **OAuth** — configure any combination of GitHub, Google, Discord via env vars; unconfigured providers return a 500 rather than silently failing
- **Admin** — set `config/admins.json` or `ADMIN_USERS` env var; admin flag is synced on every login
- **Dev login** — `POST /api/auth/dev-login` creates a passwordless admin user (`dev@local`); only available when `NODE_ENV !== 'production'`

## Real-time (SSE)

```js
// Server — push an event to a specific user
import appEvents from './events.mjs'
appEvents.emit(`update:${userId}`, { type: 'notification', data: { msg: 'Hello!' } })

// Client — already wired in Dashboard.tsx
const es = new EventSource(`/api/sse/stream?token=${token}`)
es.addEventListener('update', (e) => console.log(JSON.parse(e.data)))
```

## License

MIT
