# Product Specification

## Product Name

**Legends Forge** - a Dragon Ball Legends team builder and recommendation platform.

## Vision

Help players quickly turn their owned roster into the strongest possible Dragon Ball Legends team by combining reliable DBLegends.net data, transparent scoring, and a premium high-signal interface.

## Primary Users

### 1. Competitive team optimizer

- Wants the strongest lineup from owned characters.
- Cares about tag synergy, role balance, element spread, and supporter fit.
- Needs fast filtering and clear reasoning.

### 2. Collection-focused planner

- Wants to browse characters and supporters.
- Needs details, tags, episodes, and synergy clues.
- May save builds for later.

### 3. Admin / operator

- Needs visibility into sync runs and parser health.
- Needs manual sync triggers and actionable logs.

## Core Product Goals

1. Provide a fast searchable catalog of characters and supporters.
2. Keep data fresh through server-side sync from DBLegends.net.
3. Generate strong team recommendations from an owned roster.
4. Explain recommendations clearly enough for trust and iteration.
5. Support future meta heuristics and matchup-aware tuning without rewrites.

## Non-Goals for v1

- Real-time PvP matchup simulation.
- Community voting, guides, or social features.
- Browser-side scraping or direct client reads from DBLegends.net.
- Fully automated competitive tier lists.

## Success Criteria

- Public pages are SEO-friendly and fast under normal load.
- Sync can run unattended and safely detect upstream additions/updates.
- Team builder returns one best team plus strong alternatives and rationales.
- Critical flows have automated coverage for parser resilience and scoring logic.

## Key User Journeys

### Journey A: Browse the catalog

1. User lands on the home page.
2. User searches characters or supporters.
3. User filters by tags, rarity, element, role, episode, and mechanics.
4. User opens detail pages or compare views.

### Journey B: Build a team from an owned roster

1. User opens the team builder.
2. User selects owned characters and supporters.
3. User applies optional preferences such as preferred tags or required anchors.
4. System scores candidate teams.
5. User reviews the best team, alternatives, and explanation breakdown.
6. User saves the build.

### Journey C: Operate the sync

1. Admin opens a debug endpoint or scheduled job runs.
2. Sync checks source list pages and content fingerprints.
3. Changed entities are fetched and normalized.
4. Data is upserted and cache tags are invalidated.
5. Admin can inspect sync status and failures.

## Functional Requirements

### Public catalog

- Search characters by name, code, tag, episode, element, rarity, and mechanics.
- Search supporters by name, tag, episode, and support patterns.
- List pages must support sorting and multiple filter combinations.
- Character detail pages must expose traits, abilities, Z abilities, roles, and related supporters.
- Supporter detail pages must expose support abilities, level curves, tags, and recommended fits.

### Team builder

- User can select owned characters and supporters.
- User can pin required characters and exclude candidates.
- System returns:
  - best team
  - alternative teams
  - best supporter choice
  - explanation of why a recommendation won
- Saved team builds must persist in the database.

### Data sync

- Sync `/characters`, `/supporters`, and `/news`.
- Detect upstream change using source fingerprints.
- Fetch related detail pages only when needed.
- Normalize all upstream content into owned schema.
- Upsert idempotently and record sync run results.
- Prevent concurrent sync corruption with locking.
- Allow manual sync via admin/debug endpoints.

## Non-Functional Requirements

- TypeScript strict mode.
- Zod validation for upstream parsed structures.
- Maintainable architecture with clear module boundaries.
- Accessible UI with keyboard navigation, focus visibility, semantic HTML, and reduced motion support.
- Production-safe error handling and structured logging.
- Cache-aware rendering with ISR and targeted invalidation.

## Information Architecture

- Marketing landing page
- Characters index
- Character detail
- Supporters index
- Supporter detail
- Team builder
- Saved builds
- Admin sync status

## Metrics to Track Later

- Sync success rate and average duration
- Parse failure count by source type
- Team builder completion rate
- Saved build count
- Most-used tags, elements, and filters

## v1 Acceptance

The product is v1-ready when:

- docs are complete,
- app shell exists,
- database schema is migrated,
- sync pipeline is working against DBLegends.net,
- catalog pages render from owned data,
- team builder scoring works with explanation output,
- tests cover parsers and scoring,
- deployment instructions support Vercel plus Supabase.
