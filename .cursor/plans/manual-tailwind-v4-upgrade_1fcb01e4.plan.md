---
name: manual-tailwind-v4-upgrade
overview: "Manually replace Dependabot PR #3 with a controlled Tailwind v4 upgrade branch from current `main`, including config migration, DaisyUI/theme validation, and a normal PR only after local and CI-style verification pass."
todos:
  - id: close-pr-3
    content: "Close Dependabot PR #3 and note that the upgrade requires a manual migration branch because of custom Tailwind and DaisyUI setup."
    status: completed
  - id: create-manual-branch
    content: Create a manual branch from current main for the Tailwind v4 upgrade.
    status: completed
  - id: upgrade-tailwind-deps
    content: Upgrade tailwindcss-rails and reconcile the Ruby/npm Tailwind plugin setup for v4.
    status: completed
  - id: migrate-config-and-css
    content: Migrate config/tailwind.config.js and app/assets/stylesheets/application.tailwind.css to a v4-compatible shape while preserving the bankcore DaisyUI theme.
    status: completed
  - id: validate-build-paths
    content: Validate Tailwind build/watch, Rails tests, local CI, and assets:precompile after the upgrade.
    status: completed
  - id: smoke-test-ui
    content: Smoke test the key DaisyUI-heavy workstation screens for visual regressions.
    status: completed
  - id: open-manual-pr
    content: "Open a normal PR documenting that it replaces Dependabot PR #3 after validation passes."
    status: completed
isProject: false
---

# Manual Tailwind V4 Upgrade Plan

## Goal

Replace Dependabot PR `#3` with a manual upgrade path for `tailwindcss-rails` because the current app uses a custom Tailwind v3-style setup that will not be safely upgraded by a gem bump alone.

Primary source files:

- [Gemfile](/home/syckot/BankCORE_2/Gemfile)
- [config/tailwind.config.js](/home/syckot/BankCORE_2/config/tailwind.config.js)
- [app/assets/stylesheets/application.tailwind.css](/home/syckot/BankCORE_2/app/assets/stylesheets/application.tailwind.css)
- [package.json](/home/syckot/BankCORE_2/package.json)
- [Procfile.dev](/home/syckot/BankCORE_2/Procfile.dev)
- [bin/dev](/home/syckot/BankCORE_2/bin/dev)
- [.github/workflows/ci.yml](/home/syckot/BankCORE_2/.github/workflows/ci.yml)
- [Dockerfile](/home/syckot/BankCORE_2/Dockerfile)

## Why PR #3 Should Be Replaced

The open Dependabot PR only updates the gem and lockfile, but the repo currently depends on Tailwind v3 conventions and DaisyUI plugin wiring.

Key current patterns:

```1:22:/home/syckot/BankCORE_2/config/tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('daisyui'),
  ],
```

```1:8:/home/syckot/BankCORE_2/app/assets/stylesheets/application.tailwind.css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
```

That means the manual branch needs to upgrade configuration and styles together, not just the gem version.

## Step 1: Close Out the Dependabot PR

- Close PR `#3` with a note that the major upgrade requires manual migration because the app uses custom Tailwind config and DaisyUI theme/plugin setup.
- Keep the Dependabot PR as historical context, but move the real work to a normal branch from current `main`.

## Step 2: Create a Manual Upgrade Branch

- Branch from up-to-date `main`.
- Suggested branch name: `chore/manual-tailwind-v4-upgrade`.
- Treat this as a standalone migration branch, not a follow-up to the Dependabot branch.

## Step 3: Upgrade the Tailwind Tooling Intentionally

Update the dependency layer first:

- bump `tailwindcss-rails` in [Gemfile](/home/syckot/BankCORE_2/Gemfile)
- refresh `Gemfile.lock`
- verify the plugin/runtime relationship in [package.json](/home/syckot/BankCORE_2/package.json) and `package-lock.json`

Then run the official upgrade path on the manual branch:

- prefer `bin/rails tailwindcss:upgrade` or the equivalent Tailwind upgrade workflow
- expect follow-up manual cleanup because this repo has custom JS config and DaisyUI theming

## Step 4: Migrate Tailwind Config and CSS Entry Point

Refactor the current Tailwind v3 setup to a v4-compatible shape.

Main migration targets:

- [config/tailwind.config.js](/home/syckot/BankCORE_2/config/tailwind.config.js)
- [app/assets/stylesheets/application.tailwind.css](/home/syckot/BankCORE_2/app/assets/stylesheets/application.tailwind.css)

Specific concerns to address:

- preserve the custom `bankcore` DaisyUI theme
- preserve plugin support for `daisyui`, `@tailwindcss/forms`, `@tailwindcss/typography`, and `@tailwindcss/container-queries`
- convert the stylesheet entrypoint away from pure v3 directives if the upgrade tool rewrites it
- verify `@apply`-heavy semantic classes like `.app-shell`, `.ui-panel`, `.ui-status-pill`, and ledger/workstation primitives still compile cleanly

## Step 5: Validate Dev and Build Paths

Validate the actual compile paths used by this repo, not just Rails tests.

Local/dev path:

- [Procfile.dev](/home/syckot/BankCORE_2/Procfile.dev)
- [bin/dev](/home/syckot/BankCORE_2/bin/dev)

CI path:

- [.github/workflows/ci.yml](/home/syckot/BankCORE_2/.github/workflows/ci.yml)

Production-style path:

- [Dockerfile](/home/syckot/BankCORE_2/Dockerfile)

Validation focus:

- `bin/rails tailwindcss:build`
- `bin/dev` or the watcher path from `Procfile.dev`
- `bin/rails test`
- `bin/ci`
- `bin/rails assets:precompile`

This matters because this repo’s current GitHub Actions test job does not explicitly precompile assets, while the Docker build does.

## Step 6: Smoke Test the Most Tailwind/DaisyUI-Heavy Screens

Manually verify pages that depend heavily on DaisyUI tokens and custom semantic classes.

Highest-value screens:

- [app/views/layouts/application.html.erb](/home/syckot/BankCORE_2/app/views/layouts/application.html.erb)
- [app/views/transactions/new.html.erb](/home/syckot/BankCORE_2/app/views/transactions/new.html.erb)
- [app/views/shared/_flash.html.erb](/home/syckot/BankCORE_2/app/views/shared/_flash.html.erb)
- [app/views/accounts/_form.html.erb](/home/syckot/BankCORE_2/app/views/accounts/_form.html.erb)
- [app/views/sessions/new.html.erb](/home/syckot/BankCORE_2/app/views/sessions/new.html.erb)

Watch specifically for:

- DaisyUI theme token regressions (`bg-base-100`, `text-base-content`, `border-base-300`)
- spacing regressions from `space-y-*`
- shadow and border visual changes
- broken form/input/select/button styling

## Step 7: Open a Normal PR From the Manual Branch

Only open the PR after:

- dependency changes are complete
- config/CSS migration is stable
- local validation passes
- key screens have been smoke-tested

Suggested PR framing:

- explain that this replaces Dependabot PR `#3`
- call out the custom Tailwind/DaisyUI migration work explicitly
- include a test plan with build, test, and smoke-test steps

## Expected Risks

- DaisyUI custom theme compatibility with Tailwind v4
- CSS entrypoint rewrite from v3 directives
- subtle workstation UI regressions from spacing/shadow changes
- asset compile differences between local dev, CI, and Docker precompile

