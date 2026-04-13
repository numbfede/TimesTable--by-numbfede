# Data ingestion — DBLegends.net sync pipeline

## 1. Goals

- **Server-side only** ingestion (route handlers, server actions, or background jobs — never the browser).
- **Resilient** to minor HTML/CSS class changes: parsers prefer semantic anchors (e.g. `article`, `h1`, stable `href` patterns) and degrade gracefully.
- **Idempotent**: re-running sync does not duplicate rows or flip-flop canonical data.
- **Observable**: every run recorded in `sync_runs` with per-page outcomes.

## 2. Source endpoints (v1 scope)

| Seed URL | Purpose |
|----------|---------|
| `https://dblegends.net/characters` | Discover character list links; detect new/changed rows |
| `https://dblegends.net/supporters` | Discover supporter list links |
| `https://dblegends.net/news` | Detect news items relevant to “data changed” signals |

**Note:** Exact detail URL patterns will be captured in fetcher fixtures during implementation (Phase 3). List pages are the **discovery** source; detail pages are the **authority** for normalization.

## 3. Fingerprints and change detection

### 3.1 `source_pages` model

Each fetched URL has:

- `url` (unique)
- `page_kind` — enum: `list_characters` | `list_supporters` | `list_news` | `detail_character` | `detail_supporter` | `detail_news` | `unknown`
- `raw_hash` — SHA-256 of **canonical raw bytes** (normalized whitespace optional; prefer raw body hash for simplicity)
- `fetched_at`, `http_status`, `parse_version`
- `parse_ok`, `parse_error` (nullable)

### 3.2 Sync decision

1. Fetch seed list pages; compute `raw_hash`.
2. Compare with last successful `source_pages.raw_hash` for that URL.
3. If unchanged **and** no “force full” flag: skip heavy detail refetch except **stale** detail pages older than TTL (configurable, e.g. 7 days).
4. If changed: parse list HTML for hrefs; **upsert** discovered logical ids; enqueue detail fetches for:
   - entities not in DB,
   - entities whose list row fingerprint changed (if derivable),
   - entities over TTL.

**List hash alone** may not reveal which single character changed; v1 strategy:

- On **any** list page hash change: diff **set of slugs** parsed from the list against DB; fetch details only for **new** slugs plus **random sample** optional (off by default).
- For **updated** characters without slug set change: rely on **detail TTL refresh** and optional “news” triggers (see §6).

## 4. Parsing strategy (markup-tolerant)

- **Stage A — Link discovery**: parse anchors matching known path prefixes (`/character/`, `/characters/`, etc. — to be verified in code).
- **Stage B — Detail extraction**: multiple CSS selectors in priority order; first match wins; log when falling back.
- **Stage C — Normalization**: Zod validates **canonical** record; invalid fields dropped with warning, not fatal unless required fields missing.
- **Version parsers**: `parse_version` string in DB; allows replay migration when upgrading parsers.

## 5. Normalization rules

- Every character/supporter row stores:
  - `source_url` (canonical detail URL)
  - `slug` (unique)
  - `name`, `element_id`, `rarity_id`, `updated_at_source` (if detectable)
- **Tags / episodes** extracted to junction tables `character_tags`, `supporter_tags`.
- **Abilities**: store normalized rows in `abilities_normalized` with `kind` (unique, zenkai, etc.), `title`, `description`, `order_index`; free text remains text — no fake structure.

## 6. News-assisted refresh

- Parse `/news` titles and links.
- If keywords match (`character`, `balance`, `update`, `zenkai`, `legend`, etc.) **or** hash changed: optionally set a **global “catalog dirty”** flag that lowers TTL for character detail refetch (implementation toggle).

## 7. Locking and concurrency

```text
BEGIN;
SELECT pg_advisory_lock(:sync_lock_key);
-- read fingerprints, compute work set
-- upsert entities transactionally
INSERT sync_runs (... in_progress ...);
COMMIT; -- releases advisory lock at end of session/transaction per PG semantics
```

**Rule:** Only one sync **write** phase holds the lock. Reads (public pages) never block. If lock not acquired within N seconds, exit 409 with structured log — **do not** partial-write without lock.

**Idempotent writes:** all inserts are `INSERT ... ON CONFLICT DO UPDATE` on slug or natural key.

## 8. Admin / debug endpoints (planned)

| Endpoint | Method | Auth |
|----------|--------|------|
| `/api/sync` | `POST` | `Authorization: Bearer <SYNC_SECRET>` or `CRON_SECRET` |
| `/api/sync/status` | `GET` | Same or read-only admin token |

Response JSON: `sync_run_id`, counts, duration, pages_skipped, pages_fetched, errors.

## 9. Scheduled execution

- **Vercel Cron**: `POST /api/sync` on interval (e.g. hourly); header `Authorization: Bearer $CRON_SECRET`.
- **Supabase pg_cron / Edge Function**: alternative that hits the deployed URL with the same secret.

## 10. Post-sync cache invalidation

Call `revalidateTag` for:

- `characters`, `character:{slug}`
- `supporters`, `supporter:{slug}`
- `news` (if surfaced)
- `home` marketing stats (optional)

Tag list centralized in `lib/cache/tags.ts`.

## 11. Testing strategy (ingestion)

- **Fixtures**: store sanitized HTML snippets under `lib/dblegends/parsers/__fixtures__/`.
- **Tests**: parser unit tests assert **golden outputs** for fixtures; add second fixture per page type with altered CSS to prove resilience.

## 12. Main risks (ingestion-specific)

| Risk | Mitigation |
|------|------------|
| DBLegends.net structure changes | Multi-selector parsers, parse_version, fixture tests |
| Rate limits / blocking | Backoff, conditional GET if ETag available, conservative concurrency |
| Incomplete detail pages | Soft validation; surface “incomplete data” in UI |
| Over-syncing | Fingerprints + TTL + slug set diff |
