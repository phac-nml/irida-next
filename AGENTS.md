# AGENTS.md

## Project Overview

**IRIDA Next** is an open-source bioinformatics platform built by PHAC-NML for the storage, management, and Nextflow-based analysis of genomic sequences and metadata.

- **Backend:** Ruby on Rails 8 (Ruby 3.4.x), PostgreSQL 14 (`hstore` and `pg_trgm` extensions).
- **Frontend:** ViewComponent (`Pathogen::*` components), Stimulus, Turbo, Tailwind CSS, bundled with `esbuild`.
- **Workflow Execution:** Nextflow (25.10.2) via GA4GH WES (`sapporo-service` on `http://localhost:1122`).
- **Environment:** `devenv.sh` (Nix) manages all runtimes, system packages, databases, and background processes.

---

## Environment & `devenv.sh` Rules (CRITICAL)

1. **Always execute commands inside `devenv`:** Non-interactive agent subshells bypass `direnv`. Prefix **every** terminal command with `devenv shell --` (e.g., `devenv shell -- bin/rails test`).
2. **Suppress interactive TUIs:** Set `AI_AGENT=1` when running `devenv` commands or processes so `devenv` runs in non-interactive, agent-friendly quiet mode.
3. **Never run `devenv up` in the foreground:** Manage background services (`postgres`, `sapporo-service`) using structured process commands:
   - Check status: `devenv processes status`
   - View logs: `devenv processes logs <process-name>`
   - Restart service: `devenv processes restart <process-name>`
4. **Playwright & Browsers:** Nix provides Chromium/Playwright via `PLAYWRIGHT_BROWSERS_PATH` and `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`. Never run `pnpm exec playwright install` to download external browser binaries.

---

## Essential Commands

### Setup & Dependencies

- **Install Ruby gems:** `devenv shell -- bundle install`
- **Install JS dependencies:** `devenv shell -- pnpm install`
- **Prepare database (dev & test):** `devenv shell -- bin/rails db:prepare`
- **Build JS assets:** `devenv shell -- pnpm build`
- **Fix bundle/pnpm errors:** If a command fails with gem/`bundle` errors (missing gems, version mismatches) or `pnpm` errors (missing packages), run `devenv shell -- bin/setup --skip-server` to reinstall Ruby gems and JS dependencies (via `bin/setup`) without starting the dev server afterwards.

### Testing

- **Rails unit/integration tests:** `devenv shell -- bin/rails test`
- **Single Rails test file:** `devenv shell -- bin/rails test test/models/sample_test.rb`
- **Rails system tests (Playwright):** `devenv shell -- bin/rails test:system`
- **JavaScript unit tests (Vitest):** `devenv shell -- pnpm test` (or `devenv shell -- pnpm vitest run`)

### Linting & Formatting (Matches `lefthook.yml`)

Run these checks on modified files before finishing a task:

- **Ruby (RuboCop):** `devenv shell -- bundle exec rubocop -A`
- **ERB templates (Herb):** `devenv shell -- bundle exec herb format` and `devenv shell -- bundle exec herb lint`
- **JavaScript (ESLint):** `devenv shell -- pnpm eslint --fix`
- **Formatting (Prettier):** `devenv shell -- pnpm prettier --write <files>`
- **Locale normalization (i18n-tasks):** `devenv shell -- bundle exec i18n-tasks normalize` (required whenever `config/locales/*.yml` files are modified)

---

## Architecture & Coding Conventions

### UI & ViewComponents

- **Prefer `Pathogen::*` components:** When building or updating reusable UI, use components from the `pathogen-view-components` gem.
- **Do not add new `Viral::*` components:** `Viral::*` components are legacy debt. Replace existing `Viral::*` call sites with `Pathogen::*` equivalents when touching those views rather than extending `Viral`.

### Internationalization (i18n)

- Never hardcode user-facing strings in controllers, models, components, or `.erb` views.
- Add translation keys to `config/locales/en.yml` (and corresponding locale files if applicable) and run `devenv shell -- bundle exec i18n-tasks normalize`.

### JavaScript & Assets

- Use `pnpm` exclusively for Node package management (`pnpm-lock.yaml` is the source of truth).
- Runtime JavaScript is bundled via `esbuild` (`esbuild.config.mjs`).
- Write unit tests for Stimulus controllers and JS utilities in Vitest (`vitest.config.js`).

---

## Boundaries & Restrictions

- **Do not modify Nix lockfiles** (`devenv.lock`, `flake.lock`) unless explicitly asked to upgrade environment dependencies.
- **Do not commit secrets** or local `.env` overrides.
- **Do not alter `db/schema.rb` manually;** always generate migrations via `devenv shell -- bin/rails generate migration ...` and run `devenv shell -- bin/rails db:migrate`.
