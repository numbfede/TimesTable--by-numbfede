# Team builder algorithm (v1) — rules-based scoring

## 1. Philosophy

Deliver **deterministic**, **explainable** recommendations. The engine is **modular**: each signal implements a small interface so weights and heuristics can be tuned without rewriting the orchestrator.

## 2. Inputs

- **User-owned** character ids (max 6 active slots in battle — DB Legends uses 3 fighters in many modes; v1 will target **3-fighter core team** plus bench optional flag — exact game rules confirmed during implementation).
- **User-owned** supporter ids.
- **Normalized catalog**: tags, elements, episodes, roles (if present), ability flags (coarse categories only in v1).

> **Implementation note:** If the live game uses 6-character parties with bench semantics, the engine exposes `partySize` config defaulting to game-accurate value once verified.

## 3. Outputs

```ts
type TeamRecommendation = {
  teamCharacterIds: string[];       // ordered: leader preference optional
  supporterId: string;
  score: number;
  breakdown: ScoreBreakdown[];      // per modular signal
};

type EngineResult = {
  best: TeamRecommendation;
  alternatives: TeamRecommendation[]; // top K, diverse by Jaccard distance
  explanationMarkdown?: string;       // optional pre-rendered summary
};
```

## 4. Scoring dimensions (v1)

Each dimension returns `{ points: number; reasons: string[] }`.

| Module | Signal | Idea |
|--------|--------|------|
| `tagSynergy` | Shared tags across team | Reward overlapping strong tags; cap to avoid one-tag domination |
| `elementCoverage` | Element diversity | Cover weak matchups approximately using rock-paper weights |
| `roleBalance` | Role tags (Melee/Ranged/Defense/Support) | Penalize missing role if data exists |
| `supporterFit` | Tag/episode overlap with supporter | Reward supporter abilities that “cover” team weaknesses (proxy via text keywords in v1 if needed) |
| `episodeSynergy` | Shared episode buckets | Mild reward for coherent saga teams |
| `redundancy` | Near-duplicate roles/elements | Penalize 3x same element unless “mono” mode toggle (future) |

## 5. Weighting

Central `WEIGHTS` map (numbers sum to 1 for interpretability):

```ts
const DEFAULT_WEIGHTS = {
  tagSynergy: 0.30,
  elementCoverage: 0.25,
  roleBalance: 0.15,
  supporterFit: 0.15,
  episodeSynergy: 0.10,
  redundancy: 0.05, // applied as penalty subtracted after weighted sum
};
```

Tuning process: adjust constants + snapshot tests for expected ordering on fixture teams.

## 6. Search strategy

- **v1**: bounded exhaustive search for party size ≤ 3 from owned pool ≤ ~30 (combinatorial C(n,3)); supporters evaluated independently per team candidate.
- **Larger pools**: optional beam search / genetic refinement (future); v1 shows warning when pool > threshold.

## 7. Diversity of alternatives

After sorting by score:

1. Take top N candidates (e.g. 50).
2. Greedy select K teams maximizing **score - λ * Jaccard(tags)** vs. already picked.

## 8. Explanation panel copy

Each `ScoreBreakdown` entry maps to UI:

- Title = module name (humanized).
- Bullets = `reasons` strings (max 3 shown, rest behind “more”).

## 9. Testing

- Golden tests: small synthetic characters with controlled tags/elements.
- Property tests (optional): symmetry where swapping identical units does not change score.

## 10. Future: meta and matchups

- `MetaSignal` interface reading external tier table versioned by season.
- `MatchupSignal` reading opponent tag/element priors.

## 11. API shape (planned)

`POST /api/team-builder/recommend` accepts Zod body `{ characterIds: string[], supporterIds: string[], options?: { limit: number } }` and returns `EngineResult` JSON.
