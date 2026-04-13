# Product specification — DB Legends Team Builder

## 1. Vision

Help players assemble **strong, coherent teams** from the characters and supporters they **actually own**, with **transparent reasoning** (not black-box “AI”), backed by data that **stays current** when DBLegends.net updates.

## 2. Target users

- **Competitive / ranked players** who want fast filtering, comparisons, and meta-aware suggestions (v1: rules-based; future: rankings / matchups).
- **Collectors / casual players** who want guidance on tag synergy and “what to run next.”

## 3. Core jobs-to-be-done

1. Discover and filter the full **character** and **supporter** catalogs with low friction.
2. Inspect **detail** pages (tags, element, rarity, key ability hooks we can normalize).
3. Build a **team** from owned units, pick a **supporter**, and see **why** the app recommends a composition.
4. **Save** builds for later (auth-ready; v1 may use anonymous + account path).

## 4. Features (by release slice)

### 4.1 Catalog

- **Search** full-text or slug/name match (implementation detail in Phase 4).
- **Filters**: element, rarity, tags, episode/saga groupings (as available from normalized data).
- **Sort**: name, rarity tier, element (exact sort set TBD from schema).

### 4.2 Detail pages

- **Character detail**: identity, element, rarity, tags, normalized ability highlights, link to canonical DBLegends.net page (attribution).
- **Supporter detail**: same pattern for supporter-specific fields.

### 4.3 Team builder

- **Roster selection** from user-owned subset (checkbox / pin flow).
- **Recommended team generator** (v1: deterministic scoring engine).
- **Outputs**: best team, alternatives, best supporter, **explanation panel** (bullet breakdown per scoring dimension).
- **Saved builds** persisted per user when auth is enabled; structure supports guest migration later.

### 4.4 Data freshness

- **Background sync** from DBLegends.net list roots: `/characters`, `/supporters`, `/news`.
- **Change detection** via content fingerprints; detail pages fetched only when needed.
- **Admin / debug** endpoints to trigger sync manually (secured).

## 5. Non-goals (v1)

- Real-time PvP matchup prediction with verified tier data (reserved for future **meta** module).
- Client-side scraping or user-provided raw HTML as primary ingestion.
- Official game API (none documented for public use; we treat DBLegends.net as external catalog source).

## 6. UX principles

- **Dark-first**, glassy, cinematic, **readable** (contrast over blur).
- **Desktop-first** power layout with **responsive** catalog and builder.
- **Motion**: subtle, purposeful; **respect `prefers-reduced-motion`**.

## 7. Success metrics (product)

- Time-to-first-recommendation under typical catalog size (engineering target in Phase 5).
- Sync reliability: failed runs logged, zero duplicate corruption under concurrent triggers.
- Parser resilience: tests pass on fixture drift scenarios (Phase 6).

## 8. Compliance and attribution

- Display **clear attribution** to DBLegends.net on detail pages and in footer.
- Respect `robots.txt` and reasonable fetch rate limits in the ingestion layer.
- Store **canonical source URL** per entity for traceability.

## 9. Open questions (to resolve during implementation)

- Exact URL patterns for character/supporter detail pages on DBLegends.net (discovered during fetcher implementation).
- Which ability fields are stable enough for Zod schemas vs. stored as semi-structured JSON with a versioned schema.
