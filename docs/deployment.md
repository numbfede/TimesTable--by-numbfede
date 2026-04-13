# Deployment and operations

## 1. Target platforms

- **Frontend + server**: Vercel (Next.js 16).
- **Database + auth**: Supabase project (Postgres).

## 2. Environment variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Client + server | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client | Public anon key (RLS-scoped) |
| `SUPABASE_SERVICE_ROLE_KEY` | **Server only** | Bypass RLS for sync job writes |
| `DATABASE_URL` or `SUPABASE_DB_URL` | Server migrations / direct SQL | Optional if not using Supabase HTTP for DDL |
| `SYNC_SECRET` | Server | Bearer token for manual `/api/sync` |
| `CRON_SECRET` | Server | Bearer for Vercel Cron requests |
| `NEXT_PUBLIC_SITE_URL` | Build/runtime | Canonical URL for links and OG |

**Never** commit `.env`. Provide `.env.example` in Phase 2.

## 3. Vercel Cron

`vercel.json` (or dashboard cron) entry:

- **Schedule**: e.g. `0 * * * *` (hourly) — tune to politeness vs. freshness.
- **Request**: `POST https://<deployment>/api/sync` with header `Authorization: Bearer <CRON_SECRET>`.

## 4. Supabase scheduled jobs (alternative)

- **pg_cron** calling a Edge Function or HTTP endpoint mirroring `/api/sync`.
- Same secret verification pattern.

## 5. Database migrations

- SQL under `supabase/migrations/*` versioned chronologically.
- Apply via Supabase CLI in CI/CD or locally: `supabase db push`.

## 6. RLS rollout

- Before public accounts: tables world-readable where appropriate (`characters`), user tables locked.
- When auth ships: enable RLS on `saved_team_builds` for `auth.uid()`.

## 7. Observability

- Vercel function logs for sync duration / errors.
- Optional Sentry DSN (`SENTRY_DSN`) in later phase.

## 8. Domains and SEO

- `metadata` API for marketing pages; `sitemap.xml` + `robots.txt` routes.
- ISR for catalog indexes; `revalidateTag` after sync.

## 9. Incident playbooks

- **Sync failing**: check `sync_runs` row; replay with manual POST after parser fix.
- **Parser drift**: deploy hotfix with incremented `parse_version`; optional targeted re-fetch.
