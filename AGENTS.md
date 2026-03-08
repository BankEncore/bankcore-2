# BankCORE / BankEncore — AI Agent Context

## Project Identity

Core banking platform built on the BankCORE financial kernel and BankEncore operating platform. The architecture follows a **posting-first philosophy**: every financial event originates as an operational action and resolves through a balanced, immutable, atomic posting engine.

## Non-Negotiable Financial Invariants

- **Balanced Posting**: No event posts unless SUM(debits) == SUM(credits)
- **Immutability**: Posted records are permanent; corrections require explicit reversals
- **Atomicity**: All-or-nothing posting; rollback on any failure
- **Derivable Balances**: `account_balances` is a cache; authoritative balances derive from posting history
- **Idempotency**: Duplicate requests must not create duplicate postings

## Tech Stack

- Rails 8.1, MySQL, Hotwire (Turbo + Stimulus)
- TailwindCSS + DaisyUI (theme: `bankcore`)
- Propshaft for assets

## Key Reference Docs

- Architecture: `docs/00_initial_core_references/00_executive_summary_lm.md`
- Roadmap: `docs/00_initial_core_references/00_implementation_roadmap_lm.md`
- Transaction types: `docs/00_initial_core_references/first_transaction_types.md`
- Posting templates: `docs/00_initial_core_references/posting_templates.md`
- GL seed plan: `docs/00_initial_core_references/gl_account_seed_plan.md`
- UI/Theme: `docs/00_initial_core_references/tailwind_daisyui_theme_spec.md`

## Ledger Boundaries (Do Not Cross)

- **Operational Layer** → "what happened" (transactions)
- **Posting Engine** → "how it affects money" (posting_batches, posting_legs)
- **Subledger** → "how it affects customer" (account_transactions)
- **GL Layer** → "how it affects bank accounting" (journal_entries)

## When Implementing Financial Logic

1. Never update balances directly; always go through the posting engine
2. Consult `posting_templates.md` for posting leg patterns
3. Follow phased build order (P1 kernel before P2+ operational features)
4. Reversals create a new inverse PostingBatch linked to the original; never mutate posted records

---

## GitHub Workflow Execution Contract (Issue-First)

For non-trivial changes, follow this default sequence unless the user explicitly opts out:

1. Create or confirm a GitHub issue first.
2. Create a short-lived branch from `main` linked to the issue:
   - `feature/<issue>-<topic>`
   - `fix/<issue>-<topic>`
   - `chore/<issue>-<topic>`
   - `docs/<issue>-<topic>`
   - `refactor/<issue>-<topic>`
   - `test/<issue>-<topic>`
3. Implement and validate on that branch.
4. Commit with `type(scope): summary`.
5. Push the branch to `origin`.
6. Open a PR linked to the issue with:
   - summary
   - exact validation commands run
   - data/migration impact
   - financial logic risk
   - rollback/remediation notes
   - screenshots for UI changes when applicable

## Non-Trivial Change Definition

Treat a change as non-trivial if any apply:

- application/runtime code changes
- dependency changes (`Gemfile*`, `package*.json`, lockfiles)
- CI/build/deploy changes (`.github/workflows/**`, `Dockerfile`, `bin/**`)
- migrations
- transaction/posting/subledger/GL behavior changes
- more than 3 files changed (excluding docs/metadata-only edits)

## Safety Constraints

- Never commit unless explicitly requested.
- Never push unless explicitly requested.
- Never force-push `main`.
- Direct-to-main is allowed only for very small docs/metadata updates and only when explicitly requested.

## Automation Prerequisites

If automatic issue/branch/push/PR execution is requested, ensure:

- `origin` remote is configured
- GitHub auth token is available
- `gh` CLI is installed and authenticated (or use GitHub API via `curl`)

If prerequisites are missing, report what is missing and provide exact one-liner setup commands.

## Skills

A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.

### Available skills

- skill-creator: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Codex's capabilities with specialized knowledge, workflows, or tool integrations. (file: /opt/codex/skills/.system/skill-creator/SKILL.md)
- skill-installer: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos). (file: /opt/codex/skills/.system/skill-installer/SKILL.md)

### How to use skills

- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  3) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  4) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.