# UI Theme and Workstation Primitives

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore UI architecture reference  
**Purpose:** Define the visual language, DaisyUI theme direction, Tailwind semantic aliases, shell layouts, workstation primitives, density rules, and role-specific workspace patterns for the platform.

---

# 1. Overview

BankCORE / BankEncore is not a consumer-fintech product and should not look like one.

The UI should feel like a **regulated operational workstation**:

- calm
- dense
- procedural
- trustworthy
- auditable
- highly structured

The design language should support two closely related workspace modes:

1. **Back-office / operations mode** — control-room / accounting workstation
2. **Teller / branch mode** — guided transaction workstation

The uploaded back-office mockup establishes a dark structural shell, light work surfaces, compact metric cards, dense journal tables, and operational side panels. fileciteturn3file0turn3file8turn3file9

The uploaded teller mockup establishes a top shell, split workspace layout, account inquiry panel, focused transaction-entry panel, prominent drawer state, and override messaging. fileciteturn3file1turn3file3turn3file5turn3file7

The platform-level UX direction also needs to remain compatible with BankEncore’s requirements for teller operations, back-office manual entry, fee and interest processing, business-date control, overrides, and audit visibility. fileciteturn3file10turn3file11turn3file12turn3file14

---

# 2. Design Objective

The design objective is:

> a conservative, high-trust banking workstation UI with dark structural chrome, light operational surfaces, compact data density, and tightly governed semantic state color usage.

This UI should communicate:

- system control
- financial precision
- workflow clarity
- user accountability
- exception visibility

---

# 3. Core Design Principles

## 3.1 Workstation, not dashboard
The product should feel like an operational workstation, not a marketing site or executive BI dashboard.

This means:
- compact controls
- dense tables
- obvious task structure
- persistent status visibility
- restrained decoration

## 3.2 Structural dark shell, light work surfaces
Both mockups already point in this direction:
- dark navigation/top shell
- light working canvas
- visually separated action surfaces

This should become the default product-wide shell model. fileciteturn3file0turn3file1

## 3.3 Semantic color use must be strict
Color must communicate workflow meaning, not just aesthetics.

Examples:
- success / in-balance / posted
- warning / pending / override-required
- error / reject / out-of-balance
- primary action / current workspace

## 3.4 Numbers and identifiers need typographic distinction
Money, account numbers, posting references, and system identifiers should be visually distinct from labels and narrative text.

## 3.5 State and accountability must remain visible
The UI should always make it easy to understand:
- business date
- open/closed state
- current operator
- branch/workspace
- approval / override condition
- whether something is draft, posted, reversed, or failed

---

# 4. Palette Interpretation

The uploaded SCSS palette should be interpreted as a governed semantic palette rather than a loose collection of colors.

## Recommended semantic mapping

| Semantic Role | Recommended Palette Role |
|---|---|
| Primary brand / key action | French Blue |
| Secondary accent / operational support | Stormy Teal |
| Success / posted / in balance | Blue Spruce |
| Warning / review / override required | Goldenrod |
| Structural shell / nav / chrome | Deep Space Blue |
| Secondary structural dark surfaces | Charcoal Blue |
| Main work surface background | Bright Snow |

## Important note on error color
The palette still needs an explicit system error red for:
- failed posting
- out-of-balance
- rejected transactions
- hard stop validation

That red should be treated as a **system utility color**, not a brand anchor.

---

# 5. DaisyUI Theme Direction

## 5.1 Theme strategy
Use DaisyUI as a token/component system, but do not allow the stock DaisyUI look to define the product identity.

The product should:
- use a custom DaisyUI theme
- use Tailwind utilities for layout and density
- add workstation-specific semantic primitives on top

## 5.2 Recommended theme name
`bankcore`

## 5.3 Recommended DaisyUI token mapping

| DaisyUI Token | Intended Meaning |
|---|---|
| `primary` | French Blue |
| `secondary` | Stormy Teal |
| `accent` | Blue Spruce |
| `neutral` | Deep Space Blue |
| `base-100` | Bright Snow |
| `base-200` | very light cool surface |
| `base-300` | soft border surface |
| `info` | French Blue |
| `success` | Blue Spruce |
| `warning` | Goldenrod |
| `error` | system red |

## 5.4 Theme behavior recommendations
- use `neutral` mainly for shell and structural surfaces
- use `primary` for the primary commit action and current workspace emphasis
- use `accent` and `success` only for positive operational state, not decoration
- keep warnings and errors high contrast and unmistakable

---

# 6. Tailwind Semantic Alias Strategy

Use Tailwind utility composition and local semantic classes to stabilize the interface.

## 6.1 Structural aliases
- `app-shell`
- `app-sidebar`
- `app-topbar`
- `workspace-main`
- `workspace-header`
- `workspace-statusbar`

## 6.2 Surface aliases
- `ui-panel`
- `ui-panel-header`
- `ui-panel-body`
- `ui-panel-muted`
- `ui-panel-critical`
- `ui-panel-warning`

## 6.3 Data aliases
- `ui-kv-grid`
- `ui-kv-row`
- `ui-metric`
- `ui-metric-label`
- `ui-metric-value`
- `ui-ledger-table`
- `ui-status-pill`
- `ui-balance-value`

## 6.4 Workflow aliases
- `ui-actionbar`
- `ui-form-section`
- `ui-review-banner`
- `ui-override-box`
- `ui-confirm-strip`

## 6.5 Domain-oriented aliases
- `account-summary-panel`
- `business-date-badge`
- `posting-preview-panel`
- `journal-batch-panel`
- `drawer-balance-panel`
- `kernel-status-panel`

The goal is to keep layout and meaning stable as the product grows.

---

# 7. Typography Rules

The mockups already imply the correct typography strategy using Inter and JetBrains Mono. fileciteturn3file0turn3file1

## 7.1 Primary UI typeface
Use **Inter** for:
- navigation
- headings
- labels
- body text
- buttons
- tables
- help text

## 7.2 System / numeric typeface
Use **JetBrains Mono** for:
- balances
- currency values
- account numbers
- posting references
- GL numbers
- business date in machine-like contexts
- IDs and trace references

## 7.3 Typography hierarchy
### Headings
- restrained weight, not oversized
- use size to indicate workspace hierarchy, not marketing emphasis

### Labels
- usually `text-xs` or `text-sm`
- uppercase sparingly for metadata and state labels
- use boldness for operational labels, not decorative contrast

### Values
- larger than labels only when operationally important
- money values should be mono and aligned cleanly

---

# 8. Density and Spacing Profile

This application should bias toward **controlled density**, not spacious card-first design.

## 8.1 General density rule
Prefer:
- tighter rows
- smaller labels
- stronger grouping
- consistent section rhythm

Avoid:
- oversized components
- excessive whitespace
- giant cards with minimal content
- decorative padding that reduces information density

## 8.2 Suggested spacing scale
- shell padding: `p-4` to `p-6`
- panel padding: `p-4` or `p-5`
- dense form rows: `py-2.5` to `py-3`
- dense table rows: `py-2`
- section gaps: `gap-4` to `gap-6`

## 8.3 Table density rule
Operational tables should default to dense rows with:
- small metadata text
- aligned numeric columns
- stronger hover/focus states
- restrained zebra or border usage

---

# 9. Product-Wide Shell Model

## 9.1 Shared shell system
Use one product shell system across both BankCORE and BankEncore.

This ensures the platform feels like one coherent product family rather than separate apps.

## 9.2 Common shell elements
- application identity
- business date
- operator identity
- branch or workspace identity
- system open/closed status
- major action entry point

These patterns are already visible in the mockups. fileciteturn3file1turn3file6

---

# 10. Workspace Mode A — Back-Office / Operations

## 10.1 Purpose
This mode supports:
- GL monitoring
- manual adjustments
- EOD operations
- fee and interest review
- batch/journal review
- reconciliation and exception work

## 10.2 Layout model
Recommended pattern:
- persistent left sidebar
- compact top status/header strip
- main work area with table-heavy content
- optional right rail for health / status / queue information

This is aligned with the uploaded back-office mockup, including left-nav, status header, metric strip, batch table, and kernel health panel. fileciteturn3file0turn3file4turn3file6turn3file8turn3file9

## 10.3 UX characteristics
- dense tables are first-class
- monitor-like summary blocks are acceptable
- commit actions should look controlled and deliberate
- journal/account distinctions must be visually obvious
- batch status and system health should remain visible

## 10.4 Recommended primitives
- `journal-batch-panel`
- `kernel-status-panel`
- `ui-ledger-table`
- `business-date-badge`
- `ui-actionbar`

---

# 11. Workspace Mode B — Teller / Branch

## 11.1 Purpose
This mode supports:
- account inquiry
- customer transaction entry
- override awareness
- drawer awareness
- highly guided task completion

## 11.2 Layout model
Recommended pattern:
- dark top shell for branch/user/business-date context
- left inquiry/context column
- right primary transaction-entry column
- optional summary card for drawer status

This is aligned with the teller mockup’s top shell, account summary card, drawer balance card, and transaction-entry form. fileciteturn3file1turn3file3turn3file5turn3file7

## 11.3 UX characteristics
- inquiry and action should be clearly separated
- account summary should feel authoritative, not promotional
- transaction form should be procedural and step-oriented
- override messages should be impossible to miss
- primary commit action should be strongly differentiated from cancel/back actions

## 11.4 Recommended primitives
- `account-summary-panel`
- `drawer-balance-panel`
- `ui-form-section`
- `ui-override-box`
- `ui-confirm-strip`

---

# 12. Panel Rules

## 12.1 Standard operational panels
Most content should live in structured panels with:
- visible header
- clear boundary
- controlled padding
- muted background or white work surface

## 12.2 Panel hierarchy
### Primary panels
Used for:
- transaction entry
- account summary
- journal batch review
- posting preview

### Secondary panels
Used for:
- metrics
- health status
- small summaries
- related context

### Critical panels
Used for:
- override required
- out-of-balance state
- reversal confirmation
- hard-stop review

---

# 13. Table Rules

Tables are core to this product.

## 13.1 Table requirements
Operational tables should support:
- dense presentation
- aligned money columns
- strong header contrast
- clear row grouping
- status tagging
- keyboard navigability where practical

## 13.2 Journal / ledger table guidance
In journal and posting preview tables, visually distinguish:
- GL accounts
- customer accounts
- system metadata
- debit vs credit columns

The mockup already points toward this with a dedicated journal batch table. fileciteturn3file8turn3file9

## 13.3 Number alignment
All money amounts should be:
- mono
- right-aligned
- visually scannable

---

# 14. Form Rules

## 14.1 Forms are workflow instruments
Transaction forms should behave like controlled procedural instruments, not generic web forms.

## 14.2 Required characteristics
- compact but readable fields
- strong label hierarchy
- clear section boundaries
- immediate validation feedback
- obvious pending-review vs ready-to-post state

## 14.3 Teller form guidance
The teller mockup establishes the right direction: transaction type, amount, override message, and commit area should read like one coherent guided workflow. fileciteturn3file5turn3file7

## 14.4 Commit action guidance
Primary posting actions should feel deliberate and controlled.

Use wording like:
- `Post Transaction`
- `Request & Post`
- `Submit for Approval`
- `Commit Batch`

Avoid casual wording.

---

# 15. Status and Badge Rules

## 15.1 Purpose of badges
Badges should communicate operational state, not decorate the UI.

## 15.2 Recommended badge categories
- posted
- pending
- open
- closed
- in balance
- out of balance
- override required
- reversed
- suspense
- review needed

## 15.3 Visual treatment
Badges should be:
- compact
- high-contrast
- semantically colored
- never oversized

Examples already exist in the mockups for open status, in-balance drawer, and override-required treatment. fileciteturn3file5turn3file6

---

# 16. Override, Warning, and Error Treatment

This platform requires unusually strong state treatment for control-sensitive conditions.

## 16.1 Override state
Override-required UI should:
- use warning color clearly
- include concise explanation
- indicate threshold or rule violated
- present next step explicitly

The teller mockup’s supervisor override box is the correct pattern to formalize. fileciteturn3file2turn3file5

## 16.2 Error state
Hard failure or invalid posting conditions must use:
- explicit red system color
- concise explanatory text
- preserved user context
- no ambiguous “soft warning” appearance

## 16.3 Review state
Pending or review-needed state should be distinct from both success and error.

Goldenrod/warning is suitable for review/pending/override states.

---

# 17. Domain-Specific Primitive Definitions

## 17.1 `account-summary-panel`
Purpose:
- show available balance, posted balance, holds, and account identifier

Rules:
- emphasize available balance
- show posted balance and holds as subordinate values
- support masked account number display by default

This pattern is implied by the teller mockup account card. fileciteturn3file3

## 17.2 `drawer-balance-panel`
Purpose:
- summarize drawer responsibility and balancing state

Rules:
- current state must be obvious
- amount must be prominent
- reconcile action must not dominate the main teller task

This pattern is implied by the teller mockup drawer box. fileciteturn3file1

## 17.3 `journal-batch-panel`
Purpose:
- review batch entries and journal-level accounting

Rules:
- dense rows
- account classification visible
- debit/credit scanability prioritized

This pattern is implied by the back-office mockup batch panel. fileciteturn3file8turn3file9

## 17.4 `kernel-status-panel`
Purpose:
- show health of posting/business-date/EOD queues or core status

Rules:
- concise metrics only
- operational signal, not decorative analytics

The “Kernel Heartbeat” style idea from the back-office mockup is directionally correct. fileciteturn3file0

## 17.5 `business-date-badge`
Purpose:
- keep current accounting day highly visible

Rules:
- visible in shell or header at all times in transaction-critical workspaces
- visually distinct from wall-clock timestamp

This pattern is already present in both mockups. fileciteturn3file1turn3file6

---

# 18. Accessibility and Interaction Rules

## 18.1 Accessibility
The product must remain compatible with operational accessibility needs.

Minimum requirements:
- high contrast for shell and text
- visible focus states
- keyboard reachable controls
- no color-only status communication
- clear label/input associations

## 18.2 Keyboard bias
Because this is a workstation product, keyboard efficiency should be favored where feasible, especially for:
- transaction entry
- table actions
- approval flows
- account lookup

## 18.3 State persistence
Warning and override states should remain visible until resolved, not disappear on blur or minor field changes without clear cause.

---

# 19. What to Avoid

Avoid these design patterns unless explicitly justified.

## 19.1 Consumer-fintech styling
- bright gradients
- oversized hero cards
- floating decorative elements
- playful visual language

## 19.2 Excessive cardification
Do not reduce all banking information to isolated cards.

This product needs:
- tables
- structured panels
- line-item views
- procedural layouts

## 19.3 Over-rounded soft UI
Rounded corners are acceptable, but the product should still feel firm and controlled.

## 19.4 Decorative color use
Do not use success/warning colors as decoration. They need semantic credibility.

---

# 20. Relationship to BankCORE / BankEncore Architecture

This UI layer must support the platform architecture already defined in the other documents.

It must make visible and usable:
- business date
- transaction lifecycle
- posting and balance state
- fee and interest workflows
- back-office manual entry
- teller task flow
- override and audit awareness

This aligns directly with the platform’s teller, back-office, fee/interest, audit, and business-date requirements. fileciteturn3file10turn3file11turn3file12turn3file14

---

# 21. Recommended Implementation Order for UI System

## Step 1
Define DaisyUI theme tokens from the palette.

## Step 2
Create structural shell primitives.

## Step 3
Create panel, form, and table primitives.

## Step 4
Create domain-specific primitives:
- account summary
- journal batch
- override box
- business date badge

## Step 5
Apply primitives to back-office MVP screens first.

## Step 6
Apply same primitives to teller workspace later, with mode-specific layout adjustments.

---

# 22. Final Design Rule

The single most important UI rule for this platform is:

> the interface must communicate operational control before visual flourish.

If the UI always makes state, accountability, workflow, and financial meaning obvious, then it is serving the banking platform correctly.

