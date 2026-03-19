# Technology Stack

**Analysis Date:** 2026-03-08

## Languages

**Primary:**

- Ruby 3.4.7 - Rails application, all backend logic (`Gemfile`, `.ruby-version`)

**Secondary:**

- JavaScript (ESM) - Stimulus controllers, Hotwire, importmap (`app/javascript/`)
- CSS - TailwindCSS v4 compiled via pnpm (`app/assets/stylesheets/`)
- ERB/HTML - View templates and ViewComponents (`app/views/`, `app/components/`)

## Runtime

**Environment:**

- MRI Ruby 3.4.7 (with PRISM parser)
- Node.js 24 (build-time only for CSS compilation)

**Package Manager:**

- Ruby: Bundler (lockfile: `Gemfile.lock`)
- JavaScript: pnpm 10 (lockfile: `pnpm-lock.yaml`, lockfileVersion 9.0)

**Memory Allocator:**

- jemalloc2 (loaded via `LD_PRELOAD` in production Docker image)

## Frameworks

**Core:**

- Rails 8.1.2 - Full-stack web framework (`Gemfile`, `config/application.rb`)
- Hotwire (Turbo + Stimulus) - SPA-like UX without heavy JS (`turbo-rails`, `stimulus-rails`)
- GraphQL - API layer via `graphql` gem, endpoint at `/api/graphql` (`config/routes/api.rb`)

**UI Components:**

- ViewComponent >= 4.0 - Component-based view architecture (`app/components/`)
- pathogen_view_components (GitHub: `phac-nml/pathogen-view-components`, branch: main) - Design system components
- reactionview ~> 0.2.1 - Additional view helpers
- Lookbook ~> 2.3 - Component previews/docs (dev only)
- Heroicon Rails, rails_icons ~> 1.6 - Icon libraries

**Styling:**

- TailwindCSS 4.2.1 - Utility-first CSS (`app/assets/stylesheets/application.tailwind.css`)
- Flowbite ^3.1.2 - Tailwind component library
- Build: `pnpx @tailwindcss/cli` → `app/assets/builds/application.css`

**Asset Pipeline:**

- Propshaft - Modern Rails asset pipeline
- importmap-rails - ESM import maps (no bundler for JS)
- cssbundling-rails - CSS bundling integration

**Testing:**

- Minitest ~> 5.27 - Primary test framework
- Capybara + capybara-playwright-driver - System/browser tests
- Playwright 1.58.2 - Browser automation backend (pnpm dev dependency)
- Mocha - Mocking library
- Simplecov - Code coverage
- Timecop - Time manipulation
- WebMock - HTTP request stubbing
- w3c_validators - HTML validity checks
- axe-core ^4.11.1 - Accessibility testing

**Build/Dev:**

- devenv (Nix) - Reproducible dev environment (`devenv.nix`)
- Lefthook ~> 2.1 - Git hooks (`lefthook.yml`)
- Faker - Test data generation
- Brakeman - Security static analysis
- bundler-audit - Gem vulnerability audits

## Key Dependencies

**Critical:**

- `devise ~> 5.0.2` - Authentication (`config/initializers/devise.rb`)
- `omniauth` + `omniauth-saml` + `omniauth-entra-id` - SSO providers (`config/initializers/devise.rb`)
- `action_policy` + `action_policy-graphql` - Authorization framework
- `good_job ~> 4.13.3` - PostgreSQL-backed background jobs (`config/initializers/good_job.rb`)
- `graphql` + `graphiql-rails` - GraphQL API
- `logidze` - Row-level audit log via PostgreSQL triggers
- `faraday ~> 2.14` - HTTP client for external API calls (`lib/integrations/`)
- `flipper-active_record ~> 1.3.2` - Feature flags backed by DB

**Infrastructure:**

- `pg` - PostgreSQL adapter (3 databases: primary, jobs, cable)
- `solid_cable` - ActionCable backed by PostgreSQL (no Redis needed)
- `aws-sdk-s3` - AWS S3 file storage (require: false, loaded conditionally)
- `azure-blob` (GitHub: `phac-nml/azure-blob`) - Azure Blob Storage
- `google-cloud-storage ~> 1.58` - GCS file storage (require: false)
- `active_storage_validations` - File upload validation
- `activerecord_cursor_paginate ~> 0.4.1` - Cursor-based pagination
- `pagy ~> 43.3.0` - Offset pagination
- `ransack ~> 4.4.1` - Search/filter via ActiveRecord
- `search_syntax` - Custom search syntax parser
- `paranoia` - Soft deletes
- `public_activity` - Activity feed tracking
- `opentelemetry-sdk` + exporters - Distributed tracing and metrics

**Data Processing:**

- `roo ~> 3.0.0` + `roo-xls` + `spreadsheet 1.3.4` - Spreadsheet import (XLS/XLSX/CSV)
- `caxlsx` - XLSX export
- `csv` - CSV handling
- `zip_kit` - Streaming ZIP exports
- `dentaku` - Expression/formula calculator
- `activerecord_json_validator ~> 3.1.0` - JSON schema validation on AR columns
- `fx` - PostgreSQL database functions and triggers in schema
- `business_time` + `holidays` - Business day calculations for export expiry

## Configuration

**Environment:**

- Primary config via Rails credentials (`config/credentials.yml.enc` + per-environment files)
- Key runtime env vars:
  - `DATABASE_URL` / `DB_HOST` / `IRIDA_NEXT_DATABASE_PASSWORD` - Database
  - `RAILS_STORAGE_SERVICE` - Storage backend (`local`, `amazon`, `microsoft`, `google`)
  - `S3_REGION`, `S3_BUCKET_NAME` - AWS S3
  - `AZURE_STORAGE_ACCOUNT_NAME`, `AZURE_STORAGE_CONTAINER_NAME`, `AZURE_STORAGE_BLOB_HOST` - Azure
  - `GCS_PROJECT_NAME`, `GCS_BUCKET_NAME`, `GCS_KEYFILE` - Google Cloud
  - `GA4GH_WES_URL` - Nextflow/WES workflow server endpoint
  - `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`, `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` - Telemetry
  - `OTEL_METRICS_SEND_INTERVAL` - Metrics reporting interval (default 10s)
  - `RAILS_HOST`, `RAILS_PORT`, `RAILS_PROTOCOL` - URL generation
  - `RAILS_LOG_LEVEL` - Log verbosity (default `info`)
  - `ENABLE_CRON`, `CRON_CLEANUP_AFTER_DAYS` - Cron job behavior
  - `GOOD_JOB_MAX_THREADS` - Background job concurrency

**Build:**

- `eslint.config.js` - ESLint configuration
- `pnpm-lock.yaml` - JS lockfile
- `devenv.nix` / `devenv.lock` / `devenv.yaml` - Nix dev environment
- `Dockerfile` - Production container (Ruby 3.4.7-slim base)

## Platform Requirements

**Development:**

- Nix/devenv (recommended): PostgreSQL 14, Node.js 24, pnpm 10, Ruby 3.4.7
- Sapporo WES service for workflow execution testing (runs on port 1122)
- Nextflow 24.10.3 (pinned via Nix overlay)

**Production:**

- Docker (Ruby 3.4.7-slim)
- PostgreSQL (3 separate databases: primary, jobs, cable)
- Puma web server ~> 7.2 + Thruster (HTTP caching/compression proxy)
- GoodJob worker process (separate from web; `bundle exec good_job`)
- Object storage: S3, Azure Blob, or GCS (configured via `RAILS_STORAGE_SERVICE`)
- SSL terminating reverse proxy assumed (`config.assume_ssl = true`)
- i18n: English and French supported

---

_Stack analysis: 2026-03-08_
