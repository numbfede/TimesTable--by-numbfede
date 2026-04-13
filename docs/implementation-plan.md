# Phased implementation plan

## Phase 1 — Documentation and architecture (**complete**)

Deliverables: product spec, architecture, ingestion plan, DB schema, folder structure, design system, team builder algorithm, deployment notes, README index.

**Exit criteria:** Stakeholder can trace feature → layer → table → sync flow on paper.

## Phase 2 — Scaffold and design system

- Initialize Next.js 16 + TS strict + ESLint.
- Tailwind v4 + global tokens (`docs/design-system.md`).
- shadcn/ui base + `components/glass/*` primitives.
- Motion installed; reduced-motion wrapper.
- Supabase client helpers (server-only service client stub).
- `.env.example`.

**Exit criteria:** `pnpm lint` / `pnpm build` clean; marketing layout renders with glass hero.

## Phase 3 — Database and sync pipeline

- SQL migrations for schema in `docs/database-schema.md`.
- Fetchers, parsers, normalizers, Zod schemas, fixtures + parser tests.
- `POST /api/sync` with secret + advisory lock + `sync_runs` logging.
- `revalidateTag` integration after successful sync.

**Exit criteria:** Dry-run or dev sync upserts sample data; tests pass for parsers.

## Phase 4 — Catalog and detail pages

- Character/supporter list with search/filter (RSC + minimal client).
- Detail pages ISR + cache tags.
- Loading skeletons, empty/error states.

**Exit criteria:** Lighthouse-ready basics; keyboard nav through filters.

## Phase 5 — Team builder and scoring

- Implement `lib/scoring` per algorithm doc.
- `POST /api/team-builder/recommend` with Zod validation.
- UI: roster picker, results, breakdown, compare drawer.
- Saved builds API (anonymous id cookie optional; user table ready).

**Exit criteria:** Golden tests for engine; E2E or integration test for recommend flow.

## Phase 6 — Polish, tests, deployment

- Expand fixtures; fuzz HTML edge cases.
- `vercel.json` cron, deployment checklist.
- README runbooks updated.

**Exit criteria:** CI runs lint + unit tests; deployment doc verified against staging.
