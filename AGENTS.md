# AGENTS.md

## Project Overview

**IRIDA Next** is an open-source bioinformatics platform built by PHAC-NML for the storage, management, and Nextflow-based analysis of genomic sequences and metadata.

- **Backend:** Ruby on Rails 8.1 (Ruby 3.4.x), PostgreSQL 18 (`hstore` and `pg_trgm` extensions).
- **Authentication/Authorization:** Devise + OmniAuth (Entra ID, SAML); authorization via `action_policy` (`app/policies/`), not Pundit or CanCanCan.
- **Frontend:** ViewComponent (prefer `Pathogen::*` from the `pathogen_view_components` gem), Stimulus, Turbo, Tailwind CSS v4, bundled with **esbuild** (not Import Maps — there is no `config/importmap.rb`).
- **APIs:** GraphQL (`graphql` + `action_policy-graphql`), plus Rails controllers/JSON.
- **Background jobs:** GoodJob.
- **Data integrity/audit:** `paranoia` for soft deletion, `logidze` for audit history.
- **Feature flags:** Flipper, defined in `config/features.yml`.
- **Search/pagination:** Ransack, `search_syntax`, Pagy.
- **Workflow Execution:** Nextflow (pinned via `devenv.nix`) through GA4GH WES (`sapporo-service` on `http://localhost:1122`).
- **Environment:** `devenv.sh` (Nix) manages all runtimes, system packages, databases, and background processes.

---

## Environment & `devenv.sh` Rules (CRITICAL)

1. **Always execute commands inside `devenv`:** Non-interactive agent subshells bypass `direnv`. Prefix **every** terminal command with `devenv shell --` (e.g., `devenv shell -- bin/rails test`).
2. **Dash-dash is mandatory:** Use `devenv shell -- <command>`, never `devenv shell -c <command>` — `-c` runs a clean environment and produces unexpected results (missing gems/tools).
3. **Suppress interactive TUIs:** Set `AI_AGENT=1` when running `devenv` commands or processes so `devenv` runs in non-interactive, agent-friendly quiet mode.
4. **Never run `devenv up` in the foreground:** Manage background services (`postgres`, `sapporo-service`) using structured process commands:
   - Check status: `devenv processes status`
   - View logs: `devenv processes logs <process-name>`
   - Restart service: `devenv processes restart <process-name>`
5. **Playwright & Browsers:** Nix provides Chromium/Playwright via `PLAYWRIGHT_BROWSERS_PATH` and `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`. Never run `pnpm exec playwright install` to download external browser binaries.

---

## Essential Commands

### Setup & Dependencies

- **Full environment bootstrap (idempotent):** `devenv shell -- bin/setup --skip-server` (installs gems/JS deps, git hooks, syncs icons, builds JS, prepares DB; omit `--skip-server` only when a human wants the dev server to start afterward — agents should always pass `--skip-server` to avoid launching a foregrounded, blocking server process)
- **Install Ruby gems only:** `devenv shell -- bundle install`
- **Install JS dependencies only:** `devenv shell -- pnpm install`
- **Prepare database (dev & test):** `devenv shell -- bin/rails db:prepare`
- **Build JS assets:** `devenv shell -- pnpm build` (esbuild; see `esbuild.config.mjs`)
- **Fix bundle/pnpm errors:** If a command fails with gem/`bundle` errors (missing gems, version mismatches) or `pnpm` errors (missing packages), run `devenv shell -- bin/setup --skip-server` to reinstall Ruby gems and JS dependencies without starting the dev server afterward.

### Testing

- **Rails unit/integration tests:** `devenv shell -- bin/rails test`
- **Single Rails test file:** `devenv shell -- bin/rails test test/models/sample_test.rb`
- **Rails system tests (Capybara + Playwright):** `devenv shell -- bin/rails test:system` (add `HEADLESS=false` to watch the browser)
- **JavaScript unit tests (Vitest + Testing Library):** `devenv shell -- pnpm test:js` (fast feedback) or `devenv shell -- pnpm test:js:coverage` (required before opening a PR; CI enforces per-file coverage thresholds). See [docs/testing/javascript.md](docs/testing/javascript.md) for Stimulus controller test conventions (lifecycle, mocking, coverage rules).
- **CI parity:** `bin/ci` (see `config/ci.rb`) is the authoritative list of checks run in CI: setup, RuboCop, Bundler Audit, Brakeman, `bin/rails test`, `bin/rails test:system`, and a seed replant check. Run the smallest subset relevant to your change rather than the whole script.

### Linting & Formatting (Matches `lefthook.yml`)

Run these checks on modified files before finishing a task:

- **Ruby (RuboCop):** `devenv shell -- bundle exec rubocop -A`
- **ERB templates (Herb):** `devenv shell -- bundle exec herb format` and `devenv shell -- bundle exec herb lint`
- **JavaScript (ESLint):** `devenv shell -- pnpm eslint --fix`
- **Formatting (Prettier):** `devenv shell -- pnpm prettier --write <files>`
- **Locale normalization (i18n-tasks):** `devenv shell -- bundle exec i18n-tasks normalize` (required whenever `config/locales/*.yml` files are modified)
- **Security scanning:** `devenv shell -- bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` and `devenv shell -- bin/bundler-audit check --update` (part of CI; run when touching authorization, input handling, or dependencies)

---

## Architecture & Coding Conventions

### UI & ViewComponents

- **Prefer `Pathogen::*` components:** When building or updating reusable UI, use components from the `pathogen_view_components` gem (`app/components/`).
- **Do not add new `Viral::*` components:** `Viral::*` components are legacy debt. Replace existing `Viral::*` call sites with `Pathogen::*` equivalents when touching those views rather than extending `Viral`.
- **Preview/document components with Lookbook** (development only) rather than ad hoc test pages.

### Authorization

- Use `action_policy` (`app/policies/`), not Pundit/CanCanCan patterns. Policies inherit from `ApplicationPolicy < ActionPolicy::Base`. GraphQL authorization goes through `action_policy-graphql`.

### Internationalization (i18n)

- Never hardcode user-facing strings in controllers, models, components, or `.erb` views.
- Add translation keys to `config/locales/en.yml` (and corresponding locale files if applicable) and run `devenv shell -- bundle exec i18n-tasks normalize`.

### JavaScript & Assets

- Use `pnpm` exclusively for Node package management (`pnpm-lock.yaml` is the source of truth).
- Runtime JavaScript is bundled via **esbuild** (`esbuild.config.mjs`) — this project does not use Rails Import Maps.
- Write unit tests for Stimulus controllers and JS utilities in Vitest, following [docs/testing/javascript.md](docs/testing/javascript.md).

### Feature Flags

- Flags are defined in `config/features.yml` and managed via Flipper. Check an existing flag's `admin_manageable`/`enable_in_development` conventions before adding a new one.

### Data Integrity

- Soft deletion uses `paranoia` — destroying a record marks it deleted rather than removing the row; respect existing scopes (`with_deleted`, `only_deleted`) rather than querying around them.
- Audit history uses `logidze` (`has_logidze`) on select models — do not bypass it with raw SQL writes to audited columns without considering the audit trail.

## Specialized Instruction Files

This application uses specialized instruction files to define best practices for specific areas:

- Rails 8: `.github/instructions/rails8.instructions.md` for Rails 8 conventions
- Turbo/Stimulus: `.github/instructions/turbo-stimulus.instructions.md` for Hotwire patterns
- TailwindCSS: `.github/instructions/tailwind.instructions.md` for styling guidelines
- esbuild/JavaScript assets: `.github/instructions/esbuild.instructions.md` for JS bundling conventions
- View helpers: `.github/instructions/view-helpers.instructions.md` for Action View helper conventions

---

## Boundaries & Restrictions

- **Do not modify Nix lockfiles** (`devenv.lock`, `flake.lock`) unless explicitly asked to upgrade environment dependencies.
- **Do not commit secrets** or local `.env` overrides.
- **Do not alter `db/schema.rb` manually;** always generate migrations via `devenv shell -- bin/rails generate migration ...` and run `devenv shell -- bin/rails db:migrate`.
