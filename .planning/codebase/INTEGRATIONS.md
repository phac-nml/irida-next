# External Integrations

**Analysis Date:** 2026-03-08

## APIs & External Services

**Workflow Execution (GA4GH WES):**

- GA4GH Workflow Execution Service (WES) API v1 - Submits and monitors Nextflow pipelines
  - SDK/Client: Custom Faraday client at `lib/integrations/ga4gh_wes_api/v1/client.rb`
  - Connection: `lib/integrations/ga4gh_wes_api/v1/api_connection.rb`
  - Endpoint path: `ga4gh/wes/v1/`
  - Auth: Bearer token via Rails credentials (`ga4gh_wes.oauth_token`); extra headers via `ga4gh_wes.headers`
  - Server URL: `GA4GH_WES_URL` env var or `ga4gh_wes.server_url_endpoint` credential
  - Used by: `app/services/workflow_executions/submission_service.rb`, `app/services/workflow_executions/status_service.rb`, `app/services/workflow_executions/cancelation_service.rb`

**Pipelines Registry:**

- GitHub (phac-nml org) - Nextflow pipeline definitions fetched from JSON config
  - Config: `config/pipelines/pipelines.json` (versioned pipeline manifests)
  - Per-environment override: `config/pipelines/{env}.json`
  - Managed by: `lib/irida/pipelines.rb`, `lib/irida/pipeline.rb`

**HTTP Client:**

- Faraday ~> 2.14 - All outbound HTTP calls
  - Default adapter: `net_http_persistent` (connection pooling, pool_size: 5, idle_timeout: 100s)
  - Middleware: multipart upload, URL encoding, JSON decode, error raising, request logging
  - Config: `config/initializers/faraday.rb`

## Data Storage

**Databases:**

- PostgreSQL 14+ (3 separate databases per environment)
  - Primary (`irida_next_{env}`): All application data
    - Connection: `DATABASE_URL` or `DB_HOST` env var, password `IRIDA_NEXT_DATABASE_PASSWORD` in prod
  - Jobs (`irida_next_jobs_{env}`): GoodJob background job queue
    - Connection: `JOBS_DATABASE_URL` or inherits primary config
    - Migrations: `db/jobs_migrate/`
  - Cable (`irida_next_cable_{env}`): ActionCable via solid_cable
    - Migrations: `db/cable_migrate/`
  - ORM: ActiveRecord (Rails 8.1)
  - Schema format: SQL (`db/structure.sql`)
  - Audit log: Logidze (PostgreSQL triggers via `fx` gem)

**File Storage:**

- Configurable via `RAILS_STORAGE_SERVICE` env var:
  - `local` - Disk at `storage/` (development default)
  - `test` - Disk at `tmp/storage/` (test)
  - `amazon` - AWS S3 (`lib/aws-sdk-s3`)
    - Credentials: Rails credentials `aws.access_key_id` / `aws.secret_access_key`
    - Region: `S3_REGION` (default `us-east-1`)
    - Bucket: `S3_BUCKET_NAME`
  - `microsoft` - Azure Blob Storage (custom fork: `phac-nml/azure-blob`)
    - Account: `AZURE_STORAGE_ACCOUNT_NAME`
    - Container: `AZURE_STORAGE_CONTAINER_NAME`
    - Host override: `AZURE_STORAGE_BLOB_HOST`
    - Key: Rails credentials `azure_storage.storage_access_key`
  - `google` - Google Cloud Storage (`google-cloud-storage ~> 1.58`)
    - Project: `GCS_PROJECT_NAME`
    - Bucket: `GCS_BUCKET_NAME`
    - Keyfile: `GCS_KEYFILE` (path to JSON key)
  - `azurite` - Azure Blob emulator for local dev (`config/storage.yml`)
  - Config: `config/storage.yml`, `config/environments/production.rb`
  - URL expiry: `RAILS_STORAGE_URLS_EXPIRE_IN` minutes (default 30)

**Caching:**

- Rails default in-process cache (no external cache store configured)
- Asset caching: far-future expiry via Propshaft digest stamps + Thruster

## Authentication & Identity

**Primary Auth:**

- Devise ~> 5.0.2 - Local email/password authentication
  - Sessions: ActiveRecord session store (`activerecord-session_store ~> 2.1`)
  - Config: `config/initializers/devise.rb`

**SSO / Federated Auth (OmniAuth):**

- SAML 2.0 (`omniauth-saml`) - Configurable via Rails credentials (`saml.*`)
  - Attribute mappings: name, email, first_name, last_name via SAML XML claims
- Microsoft Entra ID (`omniauth-entra-id`) - OAuth2/OIDC
  - Credentials: Rails credentials `entra_id.client_id`, `.client_secret`, `.tenant_id`
- Developer provider (test only) - Email/name fields, no external IdP
- Enabled providers configured in: `config/authentication/auth_config.yml`
- CSRF protection: `omniauth-rails_csrf_protection`

**API Auth:**

- Token-based API scopes: `api` and `read_api` (`lib/irida/auth.rb`)
- CORS for cross-origin token requests: `rack-cors`, config via `config/integrations/cors_config.yml`
  - Per-environment allowed hosts with token lifespans and identifiers

**Mailer Auth:**

- SMTP credentials via Rails credentials `action_mailer.smtp_settings`
- From address: Rails credentials `action_mailer.default_from`

## Monitoring & Observability

**Distributed Tracing:**

- OpenTelemetry SDK + OTLP exporter
  - Endpoint: `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`
  - ActiveJob instrumentation: `opentelemetry-instrumentation-active_job`
  - Config: `config/initializers/opentelemetry.rb`

**Metrics:**

- OpenTelemetry Metrics SDK + OTLP metrics exporter
  - Endpoint: `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`
  - Custom reporter: `lib/irida/metrics_reporter.rb` (background thread, default 10s interval)
  - Job queue metrics: `lib/irida/job_queue_metrics.rb`
  - Send interval: `OTEL_METRICS_SEND_INTERVAL` seconds

**Logs:**

- Rails tagged logging to stdout in production (`config.logger = ActiveSupport::TaggedLogging.logger($stdout)`)
- Tagged with request ID
- Level: `RAILS_LOG_LEVEL` (default `info`)
- Health check path `/up` silenced from logs

## CI/CD & Deployment

**Hosting:**

- Docker container (production Dockerfile provided)
- Kamal deployment support mentioned in Dockerfile comments

**Dev Environment:**

- devenv (Nix) with `devenv.nix` / `devenv.lock`
- Process manager: Honcho (via devenv)
- Dev processes: Rails server, CSS watcher, GoodJob worker, Sapporo WES service

## Environment Configuration

**Required env vars (production):**

- `IRIDA_NEXT_DATABASE_PASSWORD` - Primary DB password
- `RAILS_HOST` - Application hostname for URL generation
- `RAILS_PROTOCOL` - `http` or `https`
- `RAILS_STORAGE_SERVICE` - Storage backend selection
- `RAILS_MASTER_KEY` - Rails credentials decryption

**Storage-specific (required when service is active):**

- AWS: `S3_REGION`, `S3_BUCKET_NAME` + credentials
- Azure: `AZURE_STORAGE_ACCOUNT_NAME`, `AZURE_STORAGE_CONTAINER_NAME` + credentials
- GCS: `GCS_PROJECT_NAME`, `GCS_BUCKET_NAME`, `GCS_KEYFILE`

**Optional env vars:**

- `GA4GH_WES_URL` - Workflow server (overrides credentials)
- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` - Enable tracing
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` - Enable metrics
- `OTEL_METRICS_SEND_INTERVAL` - Metrics push interval
- `ENABLE_CRON` - Enable scheduled jobs (default `true`)
- `CRON_CLEANUP_AFTER_DAYS` - Retention for soft-deleted records (default `7`)
- `GOOD_JOB_MAX_THREADS` - Worker concurrency (default 5)
- `RAILS_LOG_LEVEL` - Log verbosity (default `info`)
- `RAILS_STORAGE_URLS_EXPIRE_IN` - Presigned URL TTL minutes (default 30)
- `GRAPHIQL` - Enable GraphiQL UI in non-dev environments

**Secrets location:**

- Rails encrypted credentials (`config/credentials.yml.enc`, `config/credentials/`)
- Decrypted via `RAILS_MASTER_KEY` env var or `config/master.key`

## Webhooks & Callbacks

**Incoming:**

- OmniAuth callback routes for SAML and Entra ID SSO (`config/routes/user.rb`)
- No external webhook receivers detected

**Outgoing:**

- GA4GH WES API: workflow submission, status polling, cancellation
- Configured CORS `allowed_hosts` receive short-lived access tokens from the app (BDIP integration pattern in dev: `bdip_sheets` on port 8081, `bdip_drop` on port 8082)

## Background Jobs (GoodJob)

Cron-scheduled jobs (`config/initializers/good_job.rb`):

- `AttachmentsCleanupJob` - Daily 1 AM: hard-delete old soft-deleted attachments
- `SamplesCleanupJob` - Daily 2 AM: hard-delete old soft-deleted samples
- `DataExports::CleanupJob` - Daily 3 AM: delete expired data exports

Event-driven jobs (`app/jobs/`):

- `WorkflowExecutionJob` - Orchestrates workflow execution lifecycle
- `WorkflowExecutionSubmissionJob` - Submits run to GA4GH WES
- `WorkflowExecutionStatusJob` - Polls WES for run status
- `WorkflowExecutionCompletionJob` - Handles completed runs
- `WorkflowExecutionCancelationJob` - Cancels running workflows
- `WorkflowExecutionPreparationJob` - Prepares files/params before submission
- `WorkflowExecutionCleanupJob` - Cleans up after completion
- `AutomatedWorkflowExecutions/` - Automated pipeline execution jobs
- `DataExports/` - Export generation jobs
- `Samples/` - Sample processing jobs
- `UpdateMembershipsJob` - Group/project membership sync

---

_Integration audit: 2026-03-08_
