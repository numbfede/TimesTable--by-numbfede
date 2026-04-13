# Data Ingestion Plan

## Goals

- Sync DBLegends.net server-side only.
- Detect additions and updates reliably.
- Parse defensively against markup shifts.
- Normalize into owned schema.
- Keep sync idempotent and concurrency-safe.

## Upstream Sources

### List pages

- `https://dblegends.net/characters`
- `https://dblegends.net/supporters`
- `https://dblegends.net/news`

### Detail pages

- `https://dblegends.net/character/:id`
- `https://dblegends.net/supporter/:id`
- `https://dblegends.net/banner/:id` as future enrichment only

## Separation of Concerns

### 1. Source fetching

Responsibility:

- HTTP requests
- retries with bounded backoff
- timeout handling
- user-agent headers
- raw HTML/text capture

Modules:

- `lib/dblegends/fetchers/base-fetcher.ts`
- `lib/dblegends/fetchers/characters-fetcher.ts`
- `lib/dblegends/fetchers/supporters-fetcher.ts`
- `lib/dblegends/fetchers/news-fetcher.ts`

### 2. Source parsing

Responsibility:

- extract structured fields from raw source
- tolerate missing sections
- provide parser diagnostics

Strategy:

- parse with Cheerio or equivalent HTML traversal
- fallback to text heuristics where the markup is inconsistent
- keep parser contracts narrow and validate with Zod

Modules:

- `lib/dblegends/parsers/character-list-parser.ts`
- `lib/dblegends/parsers/character-detail-parser.ts`
- `lib/dblegends/parsers/supporter-list-parser.ts`
- `lib/dblegends/parsers/supporter-detail-parser.ts`
- `lib/dblegends/parsers/news-parser.ts`

### 3. Normalization

Responsibility:

- map parsed data into canonical enums and relation records
- infer slugs
- deduplicate tags/episodes/elements/rarities
- split ability text into normalized rows

Modules:

- `lib/dblegends/normalizers/characters.ts`
- `lib/dblegends/normalizers/supporters.ts`
- `lib/dblegends/normalizers/news.ts`

### 4. Persistence

Responsibility:

- upsert entities in the right dependency order
- persist raw source metadata
- record changed fields and sync results

Order:

1. `source_pages`
2. lookup tables
3. primary entities
4. join tables
5. abilities
6. sync result rows

### 5. Cache invalidation

Responsibility:

- compute affected cache tags and routes from changed items
- call invalidation only after persistence succeeds

### 6. UI consumption

Responsibility:

- read only from Supabase-backed tables or derived views
- never fetch DBLegends.net directly

## Fingerprinting Strategy

Each fetched page stores:

- URL
- content hash
- fetched timestamp
- upstream status code
- parse version

Fingerprint algorithm:

- normalize line endings
- remove volatile whitespace
- optionally strip obvious timestamp-only wrappers
- hash with SHA-256

If a list page fingerprint changes:

- re-parse list items
- compare discovered ids against known ids
- fetch new or touched detail pages

If a detail page fingerprint changes:

- parse and upsert entity data

## Locking Strategy

Use a Postgres advisory lock or a dedicated lock row.

Rules:

- sync exits early if lock is already held
- manual sync can report `409` with active run metadata
- lock is acquired before any mutating step
- lock release is guaranteed in `finally`

## Idempotency Strategy

- upserts use stable upstream ids
- join tables use composite uniqueness
- sync item processing can be retried safely
- unchanged fingerprints skip downstream writes
- cache invalidation runs only for changed entity ids

## Resilience to Markup Changes

- avoid brittle CSS-selector-only parsing
- support both structured HTML extraction and text section parsing
- keep parser fixtures from real pages
- store parser version in sync logs
- surface parser warnings separately from hard failures

## Suggested Tables

### `source_pages`

- `id`
- `url`
- `source_type`
- `upstream_id`
- `fingerprint_sha256`
- `raw_content_excerpt`
- `http_status`
- `fetched_at`
- `parsed_at`
- `parse_version`

### `sync_runs`

- `id`
- `source_scope`
- `status`
- `started_at`
- `completed_at`
- `triggered_by`
- `list_pages_checked`
- `detail_pages_checked`
- `changed_items_count`
- `error_message`

### `sync_run_items`

- `id`
- `sync_run_id`
- `source_type`
- `upstream_id`
- `action`
- `status`
- `message`

## Manual and Scheduled Sync

### Manual

- `POST /api/sync`
- `POST /api/sync/characters`
- `POST /api/sync/supporters`
- `POST /api/sync/news`

### Status and debugging

- `GET /api/sync/status`
- optional recent run list page later

### Scheduled

- Vercel Cron: call `/api/sync`
- Supabase scheduled jobs: invoke a protected route or edge function later

## Failure Handling

- network failure -> retry and log
- parse failure -> mark item failed, continue where safe
- DB failure -> fail run and avoid invalidation
- invalid normalized payload -> record validation errors

## Testing Strategy

- unit tests for parsers using stored fixtures
- contract tests for normalization output
- sync orchestration tests with mocked fetchers and repositories

## Future Enhancements

- banner and event enrichment
- delta snapshots
- admin dashboard for parser drift inspection
- per-source parser version migrations
