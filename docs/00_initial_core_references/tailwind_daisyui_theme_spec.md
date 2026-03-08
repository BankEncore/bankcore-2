# Tailwind + DaisyUI Theme Spec

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore frontend implementation reference  
**Purpose:** Translate the approved UI direction into a concrete TailwindCSS + DaisyUI theme specification, including theme tokens, semantic alias conventions, class guidance, and implementation rules for workstation-style banking interfaces.

---

# 1. Overview

This document defines the TailwindCSS + DaisyUI theme specification for BankCORE / BankEncore.

It turns the UI direction established in `UI_THEME_AND_WORKSTATION_PRIMITIVES.md` into an implementation-facing theme contract.

The goal is to produce a UI that feels:

- operational
- structured
- high-trust
- dense
- conservative
- workstation-oriented

The system should support both:

- back-office / operations workspaces
- teller / branch workspaces

using one coherent design language.

---

# 2. Theme Strategy

## 2.1 DaisyUI is the token layer, not the product identity
DaisyUI should provide:
- color tokens
- component baseline styles
- input/button/table/alert primitives

But the product identity should come from:
- custom theme values
- Tailwind layout composition
- workstation-specific semantic classes

## 2.2 One primary theme
Use one primary theme for the platform.

### Recommended theme name
`bankcore`

This keeps:
- back-office and teller visually related
- theme maintenance simpler
- semantic state treatment consistent across modules

## 2.3 Optional future extension
A later dark-mode variant can exist, but the primary implementation target should be:

- dark shell
- light workspace

rather than a fully dark application.

---

# 3. Source Design Direction

The uploaded mockups establish the correct UI direction:

- dark structural shell
- light operational canvas
- compact, data-dense surfaces
- obvious status treatment
- restrained use of color for meaning rather than decoration

The back-office mockup shows the preferred accounting/control-room mode. fileciteturn3file0

The teller mockup shows the preferred guided transaction-entry mode. fileciteturn3file1

The uploaded palette SCSS provides the banking brand color basis that should drive the theme token assignments.

---

# 4. Recommended Theme Token Mapping

## 4.1 Core DaisyUI tokens

Below is the recommended semantic mapping from the approved palette into DaisyUI theme tokens.

| DaisyUI Token | Intended Use |
|---|---|
| `primary` | primary commit action, selected nav state, key application identity |
| `secondary` | secondary actions, supporting accents, moderate emphasis |
| `accent` | positive operational highlight, active-but-not-primary state |
| `neutral` | shell chrome, navigation background, top bar, dark structural frame |
| `base-100` | main work surface |
| `base-200` | secondary light surfaces |
| `base-300` | borders, dividers, muted cards |
| `info` | informational notices, non-critical guidance |
| `success` | posted / in-balance / complete / healthy |
| `warning` | pending review / override needed / soft stop |
| `error` | invalid / failed / out-of-balance / rejected |

---

## 4.2 Recommended palette-role assignments

| Semantic Role | Recommended Palette Color |
|---|---|
| Primary | French Blue |
| Secondary | Stormy Teal |
| Accent | Blue Spruce |
| Neutral | Deep Space Blue |
| Base workspace | Bright Snow |
| Secondary light surface | cool light gray derived from Bright Snow |
| Border / muted surface | soft steel-gray derived neutral |
| Warning | Goldenrod |
| Success | Blue Spruce |
| Error | explicit system red outside brand palette |

---

# 5. Suggested DaisyUI Theme Shape

## 5.1 Theme object guidance
The actual values should be implemented in DaisyUI’s theme config using the palette values and derived neutrals.

### Recommended structure

```js
bankcore: {
  primary: "<French Blue>",
  "primary-content": "#ffffff",

  secondary: "<Stormy Teal>",
  "secondary-content": "#ffffff",

  accent: "<Blue Spruce>",
  "accent-content": "#ffffff",

  neutral: "<Deep Space Blue>",
  "neutral-content": "#ffffff",

  "base-100": "<Bright Snow>",
  "base-200": "<light surface>",
  "base-300": "<soft border surface>",
  "base-content": "<dark readable text>",

  info: "<French Blue>",
  "info-content": "#ffffff",

  success: "<Blue Spruce>",
  "success-content": "#ffffff",

  warning: "<Goldenrod>",
  "warning-content": "<dark text>",

  error: "<system red>",
  "error-content": "#ffffff"
}
```

## 5.2 Content-color rule
Do not assume white text works everywhere.

Specifically:
- `warning-content` should usually be dark for readability
- `base-content` should be a controlled dark neutral, not pure black

---

# 6. Recommended Supporting Tailwind Tokens

In addition to DaisyUI theme tokens, define project-level CSS variables or alias classes for workstation semantics.

## 6.1 Structural variables
Recommended CSS custom properties or semantic aliases:

- `--bc-shell-bg`
- `--bc-shell-border`
- `--bc-surface-bg`
- `--bc-surface-muted`
- `--bc-border-subtle`
- `--bc-border-strong`
- `--bc-text-primary`
- `--bc-text-muted`
- `--bc-text-mono`

## 6.2 Domain-state variables
- `--bc-state-posted`
- `--bc-state-pending`
- `--bc-state-warning`
- `--bc-state-error`
- `--bc-state-reversed`
- `--bc-state-suspense`

This keeps domain-specific meanings stable even if theme tokens evolve later.

---

# 7. Tailwind Utility Conventions

## 7.1 Shell surfaces
Use Tailwind utilities to reinforce shell structure:

### Recommended shell patterns
- shell background: `bg-neutral text-neutral-content`
- workspace background: `bg-base-100 text-base-content`
- muted surface: `bg-base-200`
- borders: `border-base-300`

### Example intent
- sidebar: dark, structural, always visually anchored
- work canvas: light and readable
- nested panels: lightly separated from canvas

---

## 7.2 Buttons

### Primary actions
Use for:
- post transaction
- commit batch
- save critical config
- confirm controlled action

Recommended baseline:
- `btn btn-primary`

### Secondary actions
Use for:
- preview
- refresh
- navigation-level actions
- controlled but non-final actions

Recommended baseline:
- `btn btn-secondary`

### Neutral actions
Use for:
- cancel
- back
- close
- informational utility actions

Recommended baseline:
- `btn btn-outline` or `btn btn-ghost` depending on context

### Destructive actions
Use for:
- reject
- reverse
- void draft
- remove pending artifact

Recommended baseline:
- `btn btn-error`

### Rule
Do not use large, marketing-style CTA buttons. Buttons should remain compact and workstation-appropriate.

---

## 7.3 Alerts and banners

### Info alerts
Use for:
- guidance
- posted notes
- date or environment notices

Baseline:
- `alert alert-info`

### Warning alerts
Use for:
- override required
- pending review
- cut-off approaching
- suspense condition

Baseline:
- `alert alert-warning`

### Error alerts
Use for:
- invalid posting
- out-of-balance batch
- failed settlement
- blocked transaction

Baseline:
- `alert alert-error`

### Success alerts
Use for:
- transaction posted
- business date closed successfully
- approval completed

Baseline:
- `alert alert-success`

---

## 7.4 Tables

Operational tables should be implemented with DaisyUI table primitives plus Tailwind density overrides.

Recommended baseline:
- `table table-zebra` only when zebra improves readability
- otherwise standard table + strong borders

Recommended Tailwind add-ons:
- `text-sm`
- compact cell padding overrides
- right-aligned numeric columns
- mono numeric values

### Table rules
- money columns right-aligned
- IDs/reference columns mono
- state columns use compact status pills
- headers should be visually stronger than generic app tables

---

## 7.5 Forms

Forms should use DaisyUI inputs but be constrained by workstation density.

Recommended baseline:
- `input input-bordered`
- `select select-bordered`
- `textarea textarea-bordered`
- `label-text` plus custom sizing rules

Recommended Tailwind add-ons:
- moderate height, not oversized
- compact section spacing
- strong label hierarchy
- visible error/help text

### Form rule
Transaction-entry screens should look procedural and controlled, not casual.

---

# 8. Semantic Alias Classes

DaisyUI tokens are not enough on their own. Add semantic aliases that encode workstation meaning.

## 8.1 Shell aliases
- `.app-shell`
- `.app-sidebar`
- `.app-topbar`
- `.workspace-main`
- `.workspace-header`
- `.workspace-statusbar`

### Expected behavior
- `.app-shell`: full-height application frame
- `.app-sidebar`: persistent dark structural nav
- `.app-topbar`: business date, operator, branch, system state

---

## 8.2 Surface aliases
- `.ui-panel`
- `.ui-panel-header`
- `.ui-panel-body`
- `.ui-panel-muted`
- `.ui-panel-warning`
- `.ui-panel-critical`

### Purpose
These prevent every panel from being assembled ad hoc.

---

## 8.3 Data aliases
- `.ui-kv-grid`
- `.ui-kv-row`
- `.ui-metric`
- `.ui-metric-label`
- `.ui-metric-value`
- `.ui-ledger-table`
- `.ui-status-pill`
- `.ui-balance-value`

### Purpose
These standardize how the product renders:
- balances
- metadata
- journal rows
- account summaries
- status states

---

## 8.4 Workflow aliases
- `.ui-actionbar`
- `.ui-form-section`
- `.ui-review-banner`
- `.ui-override-box`
- `.ui-confirm-strip`

### Purpose
These standardize the workflow feel across back-office and teller screens.

---

## 8.5 Domain aliases
- `.account-summary-panel`
- `.journal-batch-panel`
- `.posting-preview-panel`
- `.drawer-balance-panel`
- `.business-date-badge`
- `.kernel-status-panel`

These are worth formalizing because they appear repeatedly across the architecture and mockups. fileciteturn3file0turn3file1

---

# 9. Typography Theme Rules

## 9.1 Fonts
### Primary UI font
`Inter, sans-serif`

### Mono/system font
`"JetBrains Mono", monospace`

## 9.2 Tailwind font aliases
Recommended config aliases:

- `font-sans` → Inter stack
- `font-mono` → JetBrains Mono stack

## 9.3 Usage rules
Use mono for:
- money values
- account numbers
- posting references
- journal numbers
- GL codes
- business date in status contexts

Use sans for:
- all labels
- navigation
- buttons
- descriptive copy
- form field labels

---

# 10. Density Profile

## 10.1 Default density target
The app should default to **compact operational density**.

### Recommended practical defaults
- labels: `text-xs` or `text-sm`
- panel padding: `p-4` or `p-5`
- row gaps: `gap-3` to `gap-4`
- section spacing: `space-y-4` to `space-y-5`
- table cells: tighter than DaisyUI default

## 10.2 Do not optimize for showcase screenshots
Optimize for:
- scanning
- repeated use
- keyboard flow
- line-item accuracy

not for oversized visual drama.

---

# 11. State Treatment Rules

## 11.1 Posted / complete
Use `success` or `accent` conservatively.

Appropriate for:
- posted
- approved
- in balance
- complete

## 11.2 Pending / review / override
Use `warning`.

Appropriate for:
- override required
- pending approval
- suspense review
- closing checks incomplete

## 11.3 Error / failure
Use `error`.

Appropriate for:
- failed posting
- out-of-balance
- hard stop validation
- rejected transaction

## 11.4 Informational
Use `info`.

Appropriate for:
- environment notices
- branch/business-date informational context
- non-blocking guidance

---

# 12. Workspace Pattern A — Back-Office Mode

## 12.1 Theme emphasis
Back-office mode should emphasize:
- table density
- operational monitoring
- controlled action zones
- system state visibility

## 12.2 Shell behavior
- persistent left nav using neutral shell
- top status strip for business date and system state
- light workspace canvas
- optional right rail for kernel health / job queues / exceptions

## 12.3 Most-used primitives
- `.journal-batch-panel`
- `.kernel-status-panel`
- `.ui-ledger-table`
- `.business-date-badge`
- `.ui-actionbar`

This matches the uploaded back-office mockup direction. fileciteturn3file0

---

# 13. Workspace Pattern B — Teller Mode

## 13.1 Theme emphasis
Teller mode should emphasize:
- task progression
- account context
- transaction-entry clarity
- drawer/branch state visibility
- override visibility

## 13.2 Shell behavior
- top shell with operator, branch, business date
- left inquiry/context area
- right primary transaction-entry area
- secondary drawer/account summary surfaces

## 13.3 Most-used primitives
- `.account-summary-panel`
- `.drawer-balance-panel`
- `.ui-form-section`
- `.ui-override-box`
- `.ui-confirm-strip`

This matches the uploaded teller mockup direction. fileciteturn3file1

---

# 14. Recommended DaisyUI Component Usage Rules

## Use freely
- buttons
- inputs
- selects
- textareas
- alerts
- badges
- dropdowns
- menus
- tables
- tabs
- modals

## Use carefully
- cards
- stats
- steps
- breadcrumbs

### Reason
DaisyUI cards/stats can easily make the app feel too dashboard-like or consumer-facing if used without workstation discipline.

## Avoid as primary identity
- decorative hero patterns
- oversized stat tiles
- playful or highly rounded novelty components

---

# 15. Tailwind Config Recommendations

## 15.1 Extend font families
Add:
- Inter for `sans`
- JetBrains Mono for `mono`

## 15.2 Extend spacing only if needed
Prefer the standard Tailwind scale unless a repeated workstation-specific gap proves necessary.

## 15.3 Extend box shadows conservatively
Recommended:
- light panel shadow only
- avoid soft floating-card shadows

## 15.4 Border radius
Use moderate radius only.

Recommended:
- panels/buttons/inputs should feel controlled, not pillowy

---

# 16. Suggested Example Theme Intent

## 16.1 Sidebar
- `bg-neutral text-neutral-content`
- subtle active nav highlight using `primary`
- inactive nav muted but readable

## 16.2 Main workspace
- `bg-base-100 text-base-content`
- inner panels use `bg-white` or `bg-base-100` with `border-base-300`

## 16.3 Critical workflow box
- warning or error border
- high-contrast heading
- compact explanatory copy
- clear next action

## 16.4 Money values
- mono
- right-aligned where tabular
- stronger weight than surrounding metadata

---

# 17. Recommended Implementation Sequence

## Step 1
Define the DaisyUI `bankcore` theme in Tailwind config.

## Step 2
Create app shell classes.

## Step 3
Create panel/table/form aliases.

## Step 4
Create domain primitives:
- business date badge
- override box
- account summary panel
- journal batch panel

## Step 5
Apply to back-office MVP screens first.

## Step 6
Reuse the same primitives for teller mode later.

This keeps the UI system aligned with the ledger-first MVP rollout.

---

# 18. Example Class Intent Reference

## Primary commit button
```text
btn btn-primary btn-sm
```

## Warning review banner
```text
alert alert-warning text-sm
```

## Dense operational panel
```text
ui-panel border border-base-300 bg-base-100
```

## Ledger table
```text
ui-ledger-table text-sm
```

## Business date badge
```text
badge badge-outline font-mono
```

These are implementation intents, not hard design limits.

---

# 19. Relationship to Architecture Docs

This document operationalizes the UI direction defined in:

- `UI_THEME_AND_WORKSTATION_PRIMITIVES.md`
- `BANKENCORE_PLATFORM_ARCHITECTURE.md`
- `BACK_OFFICE_MVP.md`
- `MANUAL_TRANSACTION_ENTRY_MODEL.md`

It is the concrete theme/config companion to those documents.

---

# 20. Final Design Rule

The single most important theme rule is:

> Tailwind and DaisyUI should be used to express operational clarity, not stylistic novelty.

If the theme consistently reinforces workflow, accountability, numeric precision, and system state, then it is serving the platform correctly.

