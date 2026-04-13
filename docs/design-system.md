# Design system — premium glassmorphism (dark-first)

## 1. Brand feel

- **Cinematic dark** base with **deep violet / cyan** accent gradients (not neon overload).
- **Glass** as **depth**: layered panels, subtle border, soft shadow; **blur** secondary to **contrast**.
- **Typography**: strong hierarchy — display weight for hero, readable body (16px+), comfortable line-height.

## 2. Technology mapping

- **Tailwind CSS v4** — `@theme` tokens in global CSS; semantic utilities (`bg-surface-glass`, `border-glass`, `text-primary`).
- **shadcn/ui** — Button, Input, Dialog, Sheet, Dropdown, Tabs, Tooltip, ScrollArea as unstyled/styled primitives.
- **Motion** — layout shifts, staggered lists, drawer spring; disabled when `prefers-reduced-motion: reduce`.

## 3. Design tokens (CSS variables)

Proposed token set (values tuned in Phase 2):

| Token | Role |
|-------|------|
| `--bg-base` | Near-black foundation |
| `--bg-elevated` | Slightly lifted surfaces |
| `--gradient-hero` | Diagonal / radial mesh behind hero |
| `--glass-bg` | Semi-transparent panel fill |
| `--glass-blur` | `backdrop-filter` strength |
| `--glass-border` | Hairline border (light alpha) |
| `--glass-shadow` | Soft outer shadow |
| `--accent` | Primary interactive accent |
| `--accent-muted` | Secondary glow / ring |
| `--text-primary` | High contrast main text |
| `--text-secondary` | Muted but WCAG AA on surfaces |
| `--danger`, `--success` | Semantic states |

## 4. Glass component rules

1. **Contrast first**: text on glass must meet **WCAG AA** (AAA where practical for body).
2. **Blur is optional depth**: provide solid fallback `--glass-bg` opacity ≥ readability threshold.
3. **One focal glow** per view — avoid competing neon edges.
4. **Borders** > heavy drop shadows for structure.
5. **Noise**: avoid high-frequency background texture; optional 1–2% grain only.

## 5. Layout patterns

- **Marketing hero**: full-width gradient mesh + glass headline card + primary CTA.
- **App shell**: sticky **search/filter bar** with blur; content scrolls beneath.
- **Cards**: character/supporter cards with art aspect ratio, tag chips, element gem icon.
- **Compare drawer**: bottom sheet (mobile) / right sheet (desktop) using shadcn Sheet.
- **Team result panel**: split layout — roster slots left, scoring + supporter right.
- **Recommendation breakdown**: accordion or tabs (dimension per tab) with short bullet copy.

## 6. States

- **Loading**: skeleton blocks matching card geometry (no spinners-only).
- **Empty**: illustration-free copy-first; single CTA (“Reset filters”).
- **Error**: calm tone, retry action, support id (sync run id for admin).

## 7. Accessibility

- Visible **focus rings** (`:focus-visible`) using accent color; never `outline: none` without replacement.
- **Keyboard**: drawer traps focus; Esc closes; skip link to main content.
- **Semantics**: `nav`, `main`, `h1` per page; cards as `article` or `li` in list.
- **Screen readers**: filter controls labeled; live region for “3 results” updates (polite).
- **Motion**: `prefers-reduced-motion` disables parallax / large layout shifts.

## 8. Iconography

- Lucide (default shadcn) for UI chrome; element/rarity as **small consistent badges** (color + label).

## 9. File organization (UI)

```
components/
  ui/           # shadcn primitives
  glass/        # GlassPanel, GlassCard, GradientMesh, GlowButton
  team-builder/ # roster grid, result panel, breakdown
```

## 10. Anti-patterns

- Full-viewport heavy blur behind small text.
- White text on bright yellow (element badges) — use dark text on light chips where needed.
- Excessive springy motion on every hover.
