# BankCORE

BankCORE is a posting-first core banking platform built on Rails 8.1, MySQL, Hotwire, TailwindCSS, and DaisyUI.

The system centers financial truth in the posting engine:

- operational events describe what happened
- posting batches and legs describe how money moves
- account and GL views are derived projections

## Local Setup

Typical bootstrap:

```bash
cat <<'EOF' > .env
BANKCORE_DB_USERNAME=sysdba
BANKCORE_DB_PASSWORD=your-local-mysql-password
EOF

bundle install
npm install
bin/rails db:setup
bin/dev
```

## Tests

Run the Rails test suite with:

```bash
cat <<'EOF' > .env
BANKCORE_DB_USERNAME=sysdba
BANKCORE_DB_PASSWORD=your-local-mysql-password
EOF

bundle exec rails db:test:prepare test
```

## Core References

- `docs/00_initial_core_references/implementation_order.md`
- `docs/00_initial_core_references/posting_engine_rules.md`
- `docs/00_initial_core_references/posting_lifecycle.md`
- `docs/00_initial_core_references/posting_templates.md`
- `docs/github_workflow.md`

## GitHub

Repository: [BankEncore/bankcore-2](https://github.com/BankEncore/bankcore-2)

Pull requests should follow `.github/pull_request_template.md` and the workflow guidance in `docs/github_workflow.md`.
