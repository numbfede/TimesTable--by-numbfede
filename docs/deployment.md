# Deployment

## Target Platform

- Frontend and route handlers: Vercel
- Database and auth: Supabase
- Scheduled sync: Vercel Cron or Supabase scheduled jobs

## Environment Variables

```bash
NEXT_PUBLIC_APP_URL=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_DB_URL=
DBLEGENDS_BASE_URL=https://dblegends.net
SYNC_SHARED_SECRET=
LOG_LEVEL=info
```

## Supabase Setup

1. Create a Supabase project.
2. Apply migrations from `supabase/migrations`.
3. Configure auth even if anonymous browsing is the initial mode.
4. Store service-role credentials only on the server.

## Vercel Setup

1. Import repository.
2. Set Node version compatible with Next.js 16.
3. Add environment variables.
4. Deploy production and preview environments.

## Scheduled Sync Options

### Option A: Vercel Cron

- Configure a cron job that hits `POST /api/sync`.
- Protect the route with `SYNC_SHARED_SECRET`.
- Use a frequency appropriate for source freshness and budget.

### Option B: Supabase Scheduled Jobs

- Call the protected sync route from a scheduled task.
- Alternative future option: move sync orchestration into an edge function while keeping parser code shared.

## Security Notes

- Never expose service-role keys to the client.
- Require a shared secret or authenticated admin context for manual sync endpoints.
- Validate request payloads with Zod.
- Prepare future RLS rules for saved builds.

## Observability

- Record sync results in `sync_runs` and `sync_run_items`.
- Emit structured logs from route handlers and sync modules.
- Integrate Sentry or equivalent later for production exception reporting.

## Production Checklist

- migrations applied
- env vars set
- cron configured
- sync endpoint protected
- parser fixtures committed
- tests green
- lint clean

## Cache and Revalidation

- public pages should use ISR where appropriate
- changed entities should trigger targeted `revalidateTag`
- avoid broad cache invalidation unless the source shape changes drastically

## Backup and Recovery

- rely on Supabase managed backups
- retain source page metadata for auditability
- keep sync logs long enough to inspect parser drift over time

## Local Development

1. install dependencies
2. create `.env.local`
3. run the app locally
4. run tests
5. manually exercise sync endpoints against DBLegends.net

## Future Hardening

- admin UI for sync monitoring
- read replicas or caching if traffic grows
- rate-limit manual sync endpoints
