# Folder structure

Chosen layout for **Next.js 16 App Router** with clear domain boundaries.

```text
/workspace
├── README.md
├── docs/
│   ├── product-spec.md
│   ├── architecture.md
│   ├── data-ingestion.md
│   ├── design-system.md
│   ├── team-builder-algorithm.md
│   ├── deployment.md
│   ├── database-schema.md
│   ├── folder-structure.md
│   └── implementation-plan.md
├── app/
│   ├── (marketing)/
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── (app)/
│   │   ├── layout.tsx
│   │   ├── characters/
│   │   ├── supporters/
│   │   └── team-builder/
│   ├── api/
│   │   ├── sync/
│   │   │   └── route.ts
│   │   └── team-builder/
│   │       └── recommend/
│   │           └── route.ts
│   ├── globals.css
│   └── layout.tsx
├── components/
│   ├── ui/                 # shadcn primitives
│   ├── glass/              # GlassPanel, GradientMesh, etc.
│   └── team-builder/       # Roster, results, breakdown
├── lib/
│   ├── dblegends/
│   │   ├── fetchers/
│   │   ├── parsers/
│   │   ├── normalizers/
│   │   └── types.ts
│   ├── scoring/
│   │   ├── engine.ts
│   │   ├── modules/
│   │   └── weights.ts
│   ├── cache/
│   │   └── tags.ts
│   ├── db/
│   │   ├── client.ts
│   │   └── repositories/
│   └── utils.ts
├── supabase/
│   └── migrations/
├── tests/                  # or colocated **/*.test.ts
└── package.json
```

## Notes

- **`app/(marketing)`** — landing, SEO, static/ISR content.
- **`app/(app)`** — authenticated-feeling shell later; catalog + builder routes live here.
- **`lib/dblegends`** — all external HTML handling; **no imports** from `components/`.
- **`lib/scoring`** — pure TS; used by route handlers and tests only.
- **Tests** — colocated next to modules or under `tests/`; fixtures beside parsers.
