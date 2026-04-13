# Team Builder Algorithm

## Goal

Recommend the best possible Dragon Ball Legends team from a user's owned characters and supporters using a transparent rules-based scoring system.

## v1 Constraints

- No fake AI messaging.
- No opaque model-based ranking.
- Rules and weights must be inspectable and tunable.

## Inputs

- owned character ids
- owned supporter ids
- optional required character ids
- optional excluded character ids
- optional preferred tags or episodes

## Outputs

- `bestTeam`
- `alternativeTeams`
- `bestSupporter`
- `explanation`
- `scoreBreakdown`

## Candidate Strategy

Because the full combination space can explode quickly, v1 uses a bounded search:

1. filter to eligible owned characters
2. identify anchor candidates with strong synergy signals
3. generate combinations of the target team size
4. prune low-potential combinations early
5. score remaining teams
6. attach the best supporter fit to each high-ranking team

## Scoring Dimensions

Each team receives weighted sub-scores.

### 1. Tag synergy

Measures overlap and complementarity across shared tags.

Signals:

- shared primary tags
- beneficial cross-tag Z Ability coverage
- tag alignment with supporter tags

### 2. Element coverage

Measures whether the team covers enough element spread without leaning too hard into one weakness.

Signals:

- distinct elements represented
- duplicate element soft penalty
- optional bonus for balanced offensive spread

### 3. Role balance

Measures functional diversity.

Signals:

- melee/ranged/support/defense mix
- lack of frontline damage penalty
- lack of sustain or utility penalty

### 4. Supporter fit

Measures how well a supporter amplifies the team.

Signals:

- tag alignment
- episode alignment
- offensive or defensive stat support fit
- support ability text heuristics

### 5. Episode synergy

Measures story/arc affinity when it creates meaningful overlap.

Signals:

- shared episodes
- episode-based Z Ability support
- bonus for cohesive arc stacks where roles remain balanced

### 6. Redundancy penalties

Subtracts value for overly repetitive or conflicting teams.

Signals:

- too many same-role members
- too many same-element members
- overlapping specialization with no added coverage

## Example Weight Set

```text
tagSynergy: 0.34
elementCoverage: 0.18
roleBalance: 0.18
supporterFit: 0.14
episodeSynergy: 0.10
redundancyPenalty: -0.18
```

Weights should live in configuration, not inline logic.

## Explanation Model

Each recommendation includes:

- total score
- sub-score breakdown
- strongest positive reasons
- biggest penalties
- chosen supporter rationale
- why alternatives ranked lower

Example explanation:

- "Three core members share Universe Rep support and receive overlapping Z Ability value."
- "Element spread covers BLU, GRN, and PUR without double-stacking low-utility roles."
- "Belmod ranks above Dende because the supporter tags align with two top damage members."

## Suggested Module Layout

- `lib/scoring/config.ts`
- `lib/scoring/types.ts`
- `lib/scoring/candidate-generator.ts`
- `lib/scoring/tag-synergy.ts`
- `lib/scoring/element-coverage.ts`
- `lib/scoring/role-balance.ts`
- `lib/scoring/supporter-fit.ts`
- `lib/scoring/episode-synergy.ts`
- `lib/scoring/redundancy.ts`
- `lib/scoring/explanations.ts`
- `lib/scoring/recommend.ts`

## Data Dependencies

Each character should expose:

- tags
- episode affiliations
- element
- rarity
- role labels
- Z Ability text and normalized boosts
- mechanics and traits

Each supporter should expose:

- tags
- episode affiliations
- support stat curves
- support ability tiers
- text-derived support archetype hints

## Testing Requirements

- unit tests for each scoring module
- golden tests for recommendation outputs on stable fixtures
- edge-case tests for small owned rosters and forced members

## Future Evolution

- matchup-aware scoring
- meta configuration profiles
- leader-slot or bench weighting
- learned heuristic tuning based on telemetry
