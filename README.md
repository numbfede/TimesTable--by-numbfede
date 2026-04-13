# DB Legends Team Builder

Production-oriented web application for **Dragon Ball Legends** team building. The app uses [DBLegends.net](https://dblegends.net) as the **external source of truth** for catalog data, ingested **only on the server**, normalized into **Postgres (Supabase)**, and consumed by a **Next.js 16** (App Router) frontend with a **premium glassmorphism** UI.

> **Status:** Phase 1 (documentation and architecture) is complete. Subsequent phases scaffold the app, sync pipeline, catalog, team builder, and polish.

## Documentation

| Document | Purpose |
|----------|---------|
| [Product spec](docs/product-spec.md) | Goals, users, features, non-goals, success metrics |
| [Architecture](docs/architecture.md) | Layers, Next.js boundaries, Supabase, caching, security |
| [Data ingestion](docs/data-ingestion.md) | Sync pipeline, fingerprints, locking, idempotency |
| [Design system](docs/design-system.md) | Tokens, glass rules, accessibility, motion |
| [Team builder algorithm](docs/team-builder-algorithm.md) | Scoring v1, modularity, explanations |
| [Deployment](docs/deployment.md) | Env vars, Vercel Cron, Supabase jobs, secrets |
| [Database schema](docs/database-schema.md) | Tables, keys, indexes, ER overview |
| [Folder structure](docs/folder-structure.md) | Repository layout aligned to Next.js |
| [Implementation plan](docs/implementation-plan.md) | Phases 2–6 exit criteria |

## Principles

1. **No client-side scraping** — all HTTP to DBLegends.net runs on the server.
2. **Resilient parsing** — tolerant HTML; Zod validates normalized shapes before persistence.
3. **Idempotent sync** — fingerprints + upserts + advisory locking; safe to re-run.
4. **Clear separation** — fetch → parse → normalize → persist → invalidate cache → UI.

## Local development (after scaffolding)

Instructions will be finalized in Phase 2. Expect:

- Node.js LTS
- `pnpm` (recommended) or `npm`
- Supabase CLI for migrations and local DB

## License

Project-specific license to be chosen by maintainers; Dragon Ball Legends and related marks are property of their respective owners. This project is a fan tool and is not affiliated with Bandai Namco or DBLegends.net.
