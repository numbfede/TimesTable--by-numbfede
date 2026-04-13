# Database Schema

## Goals

- Normalize upstream DBLegends data into query-friendly tables.
- Support idempotent sync.
- Keep future auth and saved builds straightforward.
- Preserve upstream provenance.

## Core Entity Tables

### `rarities`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| code | text unique | `ULTRA`, `SPARKING`, `EXTREME`, `HERO` |
| label | text | display label |
| created_at | timestamptz | default now() |

### `elements`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| code | text unique | `RED`, `BLU`, `GRN`, `YEL`, `PUR`, `LGT`, `DRK` |
| label | text | display label |
| created_at | timestamptz | default now() |

### `tags`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| slug | text unique | stable slug |
| name | text unique | canonical name |
| category | text | optional grouping |
| created_at | timestamptz | default now() |

### `episodes`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| slug | text unique | stable slug |
| name | text unique | canonical name |
| created_at | timestamptz | default now() |

### `characters`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| upstream_id | integer unique | DBLegends character id |
| code | text unique | e.g. `DBL55-01S` |
| slug | text unique | route slug |
| name | text | display name |
| title | text | optional variant title |
| rarity_id | uuid fk | -> `rarities.id` |
| element_id | uuid fk | -> `elements.id` |
| is_zenkai | boolean | default false |
| is_legends_limited | boolean | default false |
| role_hint | text | normalized primary role |
| portrait_url | text | optional |
| icon_url | text | optional |
| stats_json | jsonb | canonical numeric stats |
| traits_json | jsonb | normalized mechanics if not fully relational yet |
| source_updated_at | timestamptz | upstream date if available |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

Indexes:

- unique on `upstream_id`
- unique on `code`
- unique on `slug`
- index on `rarity_id`
- index on `element_id`

### `supporters`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| upstream_id | integer unique | DBLegends supporter id |
| code | text unique | e.g. `DBL-SUP-000` |
| slug | text unique | route slug |
| name | text | display name |
| icon_url | text | optional |
| role_hint | text | inferred support archetype |
| support_stats_json | jsonb | stat curves and snapshots |
| source_updated_at | timestamptz | upstream date if available |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

Indexes:

- unique on `upstream_id`
- unique on `code`
- unique on `slug`

## Join Tables

### `character_tags`

| Column | Type | Notes |
| --- | --- | --- |
| character_id | uuid fk | -> `characters.id` |
| tag_id | uuid fk | -> `tags.id` |
| is_primary | boolean | default false |
| created_at | timestamptz | default now() |

Primary key: `(character_id, tag_id)`

### `supporter_tags`

| Column | Type | Notes |
| --- | --- | --- |
| supporter_id | uuid fk | -> `supporters.id` |
| tag_id | uuid fk | -> `tags.id` |
| is_primary | boolean | default false |
| created_at | timestamptz | default now() |

Primary key: `(supporter_id, tag_id)`

### `character_episodes`

| Column | Type | Notes |
| --- | --- | --- |
| character_id | uuid fk | -> `characters.id` |
| episode_id | uuid fk | -> `episodes.id` |
| created_at | timestamptz | default now() |

Primary key: `(character_id, episode_id)`

### `supporter_episodes`

| Column | Type | Notes |
| --- | --- | --- |
| supporter_id | uuid fk | -> `supporters.id` |
| episode_id | uuid fk | -> `episodes.id` |
| created_at | timestamptz | default now() |

Primary key: `(supporter_id, episode_id)`

## Ability Storage

### `abilities_normalized`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| entity_type | text | `character` or `supporter` |
| entity_id | uuid | references by type at app level |
| ability_type | text | main, unique, z_ability, support_ability, arts, etc. |
| tier | text | I, II, III, IV, Lv99, etc. |
| title | text | title or label |
| description | text | cleaned text |
| normalized_effects_json | jsonb | optional machine-friendly effects |
| sort_order | integer | deterministic display order |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

Indexes:

- index on `(entity_type, entity_id)`
- index on `ability_type`

## Source and Sync Tables

### `source_pages`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| source_type | text | character_list, character_detail, supporter_list, supporter_detail, news |
| upstream_id | text | nullable for list pages |
| url | text unique | fetched URL |
| fingerprint_sha256 | text | content hash |
| http_status | integer | last response status |
| parse_version | text | parser version marker |
| raw_content_excerpt | text | capped snapshot for diagnostics |
| fetched_at | timestamptz | default now() |
| parsed_at | timestamptz | nullable |
| updated_at | timestamptz | default now() |

### `sync_runs`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| source_scope | text | full, characters, supporters, news |
| status | text | running, succeeded, failed, skipped |
| triggered_by | text | cron, manual, test |
| started_at | timestamptz | default now() |
| completed_at | timestamptz | nullable |
| list_pages_checked | integer | default 0 |
| detail_pages_checked | integer | default 0 |
| changed_items_count | integer | default 0 |
| invalidated_tags_json | jsonb | tags revalidated |
| error_message | text | nullable |

### `sync_run_items`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| sync_run_id | uuid fk | -> `sync_runs.id` |
| source_type | text | character, supporter, news |
| upstream_id | text | stable upstream reference |
| action | text | discovered, updated, skipped, failed |
| status | text | success, warning, error |
| message | text | optional details |
| created_at | timestamptz | default now() |

## Saved Team Tables

### `saved_team_builds`

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid pk | generated |
| user_id | uuid | auth-ready owner reference |
| name | text | user label |
| notes | text | optional |
| score_snapshot | numeric | total score at save time |
| explanation_json | jsonb | preserved explanation |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

Indexes:

- index on `user_id`

### `saved_team_build_members`

| Column | Type | Notes |
| --- | --- | --- |
| saved_team_build_id | uuid fk | -> `saved_team_builds.id` |
| character_id | uuid fk | -> `characters.id` |
| slot_index | integer | deterministic order |
| role_label | text | optional snapshot |

Primary key: `(saved_team_build_id, character_id)`

### `saved_team_build_supporters`

| Column | Type | Notes |
| --- | --- | --- |
| saved_team_build_id | uuid fk | -> `saved_team_builds.id` |
| supporter_id | uuid fk | -> `supporters.id` |
| slot_index | integer | deterministic order |

Primary key: `(saved_team_build_id, supporter_id)`

## Constraints and Integrity

- upstream ids must remain unique
- slugs must remain unique
- join tables use composite primary keys
- sync tables must be append-friendly for auditability

## RLS Preparation

- `saved_team_builds.user_id` is required for future auth policy ownership.
- public catalog tables can remain readable to anonymous users.
- admin sync endpoints are protected at the application layer.
