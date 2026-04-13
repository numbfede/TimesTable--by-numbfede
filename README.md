# Dragon Ball Legends Team Builder

A production-ready Dragon Ball Legends team-building web app built with Next.js App Router, TypeScript, Tailwind CSS v4, shadcn/ui, Motion, and Supabase. The app ingests DBLegends.net server-side, normalizes it into our own Postgres schema, and recommends strong teams using a transparent rules-based scoring engine.

## Architecture Decision Summary

- **Framework:** Next.js 16 with the App Router and server components by default for SEO, cache control, and maintainability.
- **Backend shape:** Route handlers and server functions own ingestion, team generation, persistence, and admin/debug workflows.
- **Data source strategy:** DBLegends.net is treated as an upstream source of truth, but all data is fetched server-side, fingerprinted, normalized, validated with Zod, and stored in our own Postgres tables.
- **Database:** Supabase Postgres with an auth-ready schema, RLS-ready ownership fields, sync logs, and normalized lookup tables for tags, episodes, rarities, and elements.
- **Scoring:** The recommendation engine is a modular rules-based scorer, not fake AI. It explains why a team won and exposes tunable weights for future meta iteration.
- **Caching:** Next.js cache tags plus ISR keep public pages fast. Successful syncs invalidate only affected tags and routes.
- **UI direction:** Dark-first premium glassmorphism with restrained motion, strong accessibility, and power-user-first team-building workflows.

## Chosen Folder Structure

```text
app/
  (marketing)/
  (app)/
  api/
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

## Implementation Phases

1. **Phase 1 - Docs and architecture**
   - Product spec
   - System architecture
   - Data ingestion plan
   - Design system tokens
   - Team-builder algorithm
   - Deployment plan
2. **Phase 2 - Scaffold the app and design system**
   - Next.js app shell
   - Tailwind v4
   - shadcn/ui primitives
   - glass layout components
3. **Phase 3 - Database schema and sync pipeline**
   - Supabase migration
   - normalized entities
   - sync lock and idempotent upsert pipeline
   - admin sync endpoints
4. **Phase 4 - Catalog and detail experiences**
   - character/supporter listing pages
   - filters and search
   - detail pages
   - SEO and cache tags
5. **Phase 5 - Team builder and scoring engine**
   - roster selection
   - recommendation engine
   - explanation panel
   - saved builds
6. **Phase 6 - Tests, polish, deployment**
   - parser fixtures
   - critical flow tests
   - deployment configuration
   - production hardening

## Main Risks and Mitigations

- **Upstream markup changes**
  - Mitigation: resilient server-side parsers, multiple extraction heuristics, content fingerprinting, fixtures, and sync diagnostics.
- **Data model drift**
  - Mitigation: strict normalization boundaries, Zod validation, raw source retention, source page hashing, and additive schema design.
- **Concurrent or partial sync corruption**
  - Mitigation: advisory locking, per-run transaction boundaries where possible, idempotent upserts, and sync run logging.
- **Opaque recommendations**
  - Mitigation: explanation-first scoring output with explicit category scores, penalties, and supporter rationale.
- **Performance regressions**
  - Mitigation: server rendering, selective pre-rendering, cache tags, ISR, and shallow client islands only where interactivity is required.

## Documentation

- [Product spec](docs/product-spec.md)
- [Architecture](docs/architecture.md)
- [Database schema](docs/database-schema.md)
- [Data ingestion](docs/data-ingestion.md)
- [Design system](docs/design-system.md)
- [Team-builder algorithm](docs/team-builder-algorithm.md)
- [Deployment](docs/deployment.md)

## Status

Phase 1 is the current starting point. The next phases scaffold the app and implement the production pipeline described in the docs.
