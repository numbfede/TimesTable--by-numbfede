# Design System

## Experience Direction

The product should feel premium, modern, dark, glassy, and focused. The interface emphasizes clarity and hierarchy over decorative blur.

## Design Principles

1. **Contrast first**
   - Blur and transparency never reduce readability.
2. **Depth with restraint**
   - Glass is used to separate layers, not to create noise.
3. **Power-user speed**
   - Search, filters, comparisons, and recommendation output should feel immediate.
4. **Motion with purpose**
   - Motion communicates hierarchy changes, loading, and state transitions.
5. **Accessibility is part of the aesthetic**
   - Focus states, hit targets, and typography should feel intentional, not bolted on.

## Theme

- Dark-first base
- Cinematic gradients in the background layer
- Frosted cards with subtle borders
- Controlled neon accents for actions and highlights

## Core Tokens

### Color tokens

```text
--background: #070b14
--background-elevated: rgba(16, 24, 40, 0.72)
--background-surface: rgba(13, 18, 30, 0.82)
--foreground: #f5f7fb
--foreground-muted: #aeb8cc
--border-subtle: rgba(255, 255, 255, 0.08)
--border-strong: rgba(255, 255, 255, 0.16)
--accent-primary: #6ea8ff
--accent-secondary: #9d7bff
--accent-success: #4ade80
--accent-warning: #fbbf24
--accent-danger: #fb7185
--glow-primary: rgba(110, 168, 255, 0.28)
--glow-secondary: rgba(157, 123, 255, 0.22)
```

### Radius tokens

```text
--radius-xs: 0.5rem
--radius-sm: 0.75rem
--radius-md: 1rem
--radius-lg: 1.5rem
--radius-xl: 2rem
```

### Shadow tokens

```text
--shadow-glass:
  0 10px 30px rgba(0, 0, 0, 0.35),
  inset 0 1px 0 rgba(255, 255, 255, 0.06);
--shadow-panel:
  0 20px 60px rgba(0, 0, 0, 0.45);
--shadow-glow:
  0 0 0 1px rgba(255, 255, 255, 0.08),
  0 0 30px rgba(110, 168, 255, 0.12);
```

### Blur tokens

```text
--blur-sm: 8px
--blur-md: 14px
--blur-lg: 20px
```

### Spacing rhythm

- 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64

## Typography

- Headings: bold, tight tracking, high contrast
- Body: neutral sans-serif with good x-height
- Labels: compact and clear
- Data text: tabular numerals where useful

## Layout Rules

- Marketing page uses a cinematic hero with layered panels.
- App surfaces use a sticky filter/search shell and clear content columns.
- Desktop-first layout prioritizes scanning large datasets.
- Mobile support collapses complex panels into drawers.

## Component Inventory

### Foundation

- Button
- Input
- Select
- Dialog
- Drawer
- Tabs
- Badge
- Tooltip
- Skeleton
- Separator

### Glass branded components

- `GlassPanel`
- `GlassCard`
- `GlassToolbar`
- `GlowBadge`
- `NoiseBackdrop`
- `SectionHeader`

### Feature components

- hero section
- sticky search/filter shell
- character cards
- supporter cards
- compare drawer
- team result panel
- recommendation breakdown panel
- modal/drawer detail views
- loading skeletons
- empty states
- error states

## Motion Guidelines

- Use Motion for subtle entrance, filter-panel transitions, and result state changes.
- Respect reduced motion preferences.
- Prefer opacity, translate, and scale in tight ranges.
- Avoid large parallax or continuous motion in data-heavy views.

## Accessibility Rules

- All interactive elements are keyboard reachable.
- Focus rings must be visible on glass backgrounds.
- Icon-only buttons require aria-labels.
- Filter groups use semantic labels and legends.
- Color is never the only information carrier.

## Tailwind Mapping

- Use Tailwind v4 theme variables for colors, radius, shadows, and blur.
- Keep glass effects behind semantic utility classes or component wrappers.
- Avoid repeating ad hoc blur and border values in feature code.

## shadcn/ui Guidance

- Use shadcn/ui primitives as the foundation layer.
- Apply the branded glass tokens through utility composition rather than forking primitive behavior.
- Keep shared component APIs close to upstream shadcn patterns for maintainability.

## Visual QA Checklist

- text remains readable over every glass surface
- hover and focus states are distinct
- skeletons match final density
- empty states are informative, not dead ends
- filter shells remain usable on tablets and phones
