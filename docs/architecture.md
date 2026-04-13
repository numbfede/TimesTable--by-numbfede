# Architecture

## Overview

The application is a Next.js 16 App Router system with a Supabase-backed data layer and a server-only ingestion pipeline for DBLegends.net. The architecture favors:

- server components for catalog rendering,
- thin client islands for interactive builders,
- strict separation between source acquisition and UI consumption,
- explicit cache invalidation after sync,
- modular scoring logic that can evolve without changing the product surface.

## Architectural Principles

1. **Own the data**
   - DBLegends.net is upstream, not a runtime dependency for end-user rendering.
   - All public views read from our database.
2. **Server-only ingestion**
   - No client scraping.
   - Upstream fetching is isolated in fetchers and sync jobs.
3. **Normalized persistence**
   - Canonical entities live in first-class tables with join tables for tags and other dimensions.
4. **Parser resilience**
   - Use defensive extraction rules and preserve source fingerprints.
5. **Explanation over opacity**
   - Recommendations must surface category scores and penalties.

## System Context

```text
DBLegends.net
  -> fetchers
  -> parsers
  -> normalizers
  -> persistence/upserts
  -> cache invalidation
  -> Next.js public pages / API routes / team builder
  -> Supabase Postgres
```

## Runtime Layers

### 1. UI layer

- `app/(marketing)` for landing and SEO-oriented entry points.
- `app/(app)` for the catalog, detail pages, team builder, and saved builds.
- `components/ui` for design-system primitives.
- `components/glass` for branded glassmorphism shells.
- `components/team-builder` for feature-specific interactive surfaces.

### 2. Application layer

- `app/api/sync/*` for sync endpoints and debug operations.
- `app/api/team-builder/*` for recommendation requests and saved build actions.
- server actions only where it improves UX and auth-aware persistence.

### 3. Domain layer

- `lib/dblegends/fetchers` for raw HTTP acquisition.
- `lib/dblegends/parsers` for source-specific extraction.
- `lib/dblegends/normalizers` for turning parsed data into canonical DB records.
- `lib/scoring` for candidate generation, scoring, explanations, and weight tuning.
- `lib/cache` for tags, route revalidation, and invalidation helpers.

### 4. Data layer

- `lib/db` for Supabase clients, SQL helpers, and repository-style functions.
- `supabase/migrations` for schema ownership.

## Folder Structure

```text
app/
  (marketing)/
    page.tsx
    layout.tsx
  (app)/
    characters/
      page.tsx
      [slug]/page.tsx
    supporters/
      page.tsx
      [slug]/page.tsx
    team-builder/
      page.tsx
    saved-builds/
      page.tsx
  api/
    sync/
      route.ts
      characters/route.ts
      supporters/route.ts
      news/route.ts
      status/route.ts
    team-builder/
      recommend/route.ts
      saved-builds/route.ts
components/
  ui/
  glass/
  team-builder/
docs/
lib/
  cache/
  db/
  dblegends/
    fetchers/
    parsers/
    normalizers/
  scoring/
supabase/
  migrations/
tests/
  fixtures/
  integration/
  unit/
```

## Rendering Strategy

### Server components by default

- Marketing page, character/supporter indexes, and detail pages render on the server.
- Search params are consumed server-side for initial listing queries.
- Interactive filter controls hydrate only the minimal client shell.

### Client components where needed

- Team builder roster picker
- compare drawer
- modal and detail drawers
- optimistic save interactions

## Caching Strategy

- Use ISR for list and detail pages.
- Use cache tags such as:
  - `characters`
  - `character:{id}`
  - `supporters`
  - `supporter:{id}`
  - `news`
  - `team-builder-config`
- Successful sync invalidates only affected tags using `revalidateTag`.

## Database Design Summary

The normalized schema includes at least:

- `characters`
- `supporters`
- `tags`
- `episodes`
- `rarities`
- `elements`
- `character_tags`
- `supporter_tags`
- `abilities_normalized`
- `source_pages`
- `sync_runs`
- `saved_team_builds`

Additional support tables are expected:

- `character_episodes`
- `supporter_episodes`
- `source_items`
- `sync_run_items`
- `team_build_members`
- `team_build_supporters`

## Sync Architecture

Each sync run flows through:

1. acquire lock
2. create `sync_runs` record
3. fetch list pages
4. compare source fingerprints
5. fetch changed detail pages
6. parse and validate
7. normalize
8. upsert in stable order
9. record outcomes and invalidation targets
10. revalidate cache tags
11. release lock and complete run

## Team Builder Architecture

### Inputs

- owned character ids
- owned supporter ids
- required or excluded ids
- optional preference hints

### Output

- ranked best team
- alternative teams
- best supporter fit
- explanation graph with positive factors and penalties

### Scoring modules

- tag synergy
- element coverage
- role balance
- supporter fit
- episode synergy
- redundancy penalties

## Auth-Ready Structure

Although public browsing is anonymous, persistence is designed for authenticated users:

- `saved_team_builds.user_id`
- future RLS policies
- auth-aware server clients

## Observability

- structured sync logs
- parser failure messages with source path and fingerprint
- per-item sync outcome storage
- optional Sentry-ready error hooks

## Key Decisions

1. **Use our own DB for all UI reads**
   - Avoids availability and consistency issues from upstream.
2. **Prefer Postgres normalization over large JSON blobs**
   - Keeps filters and future heuristics queryable.
3. **Use route handlers for sync and recommendation APIs**
   - Clean integration with cron and internal admin tooling.
4. **Keep scoring modular**
   - Future meta adjustments should be weight or rule changes, not rewrites.
