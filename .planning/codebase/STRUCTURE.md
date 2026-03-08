# Codebase Structure

**Analysis Date:** 2026-03-08

## Directory Layout

```
irida-next/
├── app/
│   ├── assets/             # CSS (Tailwind builds), icons (Heroicons, Phosphor SVGs)
│   ├── channels/           # ActionCable connection + channel base
│   ├── components/         # ViewComponent UI components
│   │   ├── viral/          # Internal design system components
│   │   └── [domain]/       # Domain-specific components (samples, groups, etc.)
│   ├── controllers/        # Rails controllers
│   │   ├── concerns/       # Shared controller concerns (mixins)
│   │   ├── groups/         # Nested group controllers
│   │   ├── projects/       # Nested project controllers
│   │   ├── profiles/       # User profile controllers
│   │   ├── dashboard/      # Dashboard controllers
│   │   ├── samples/        # Top-level sample controllers
│   │   ├── users/          # User management controllers
│   │   └── workflow_executions/ # Workflow execution controllers
│   ├── graphql/            # GraphQL API schema
│   │   ├── mutations/      # GraphQL mutations
│   │   ├── resolvers/      # Custom field resolvers
│   │   ├── types/          # GraphQL type definitions
│   │   ├── connections/    # Custom cursor pagination connections
│   │   ├── validators/     # GraphQL input validators
│   │   └── concerns/       # Shared GraphQL concerns
│   ├── helpers/            # Rails view helpers
│   ├── javascript/         # Stimulus JS controllers + utilities
│   │   ├── controllers/    # Stimulus controllers (mirrors server domain structure)
│   │   └── utilities/      # Shared JS utility modules
│   ├── jobs/               # ActiveJob background jobs
│   │   ├── automated_workflow_executions/
│   │   ├── data_exports/
│   │   └── samples/
│   ├── mailers/            # ActionMailer mailers
│   ├── models/             # ActiveRecord models
│   │   ├── concerns/       # Model mixins (HasPuid, History, Routable, etc.)
│   │   ├── namespaces/     # Namespace STI submodels
│   │   ├── sample/         # Sample sub-models
│   │   ├── workflow_execution/ # WorkflowExecution sub-models
│   │   └── advanced_search/ # Advanced search models
│   ├── policies/           # ActionPolicy authorization policies
│   │   └── namespaces/     # Namespace-scoped policies
│   ├── services/           # Business logic service objects
│   │   ├── attachments/
│   │   ├── automated_workflow_executions/
│   │   ├── bots/
│   │   ├── data_exports/
│   │   ├── group_links/
│   │   ├── groups/
│   │   ├── members/
│   │   ├── metadata_templates/
│   │   ├── personal_access_tokens/
│   │   ├── projects/
│   │   ├── samples/
│   │   ├── users/
│   │   └── workflow_executions/
│   ├── validators/         # Custom ActiveModel validators
│   └── views/              # ERB templates
│       ├── layouts/        # Application layouts
│       ├── shared/         # Shared partials (errors, forms, alerts)
│       ├── groups/         # Group views
│       ├── projects/       # Project views
│       ├── samples/        # Sample views
│       └── workflow_executions/
├── config/
│   ├── routes.rb           # Root router (delegates to config/routes/*.rb)
│   ├── routes/             # Split route files (group.rb, project.rb, api.rb, etc.)
│   ├── initializers/       # Rails initializers
│   ├── pipelines/          # Pipeline configuration YAML files
│   ├── schemas/            # JSON schema files for model validation
│   └── locales/            # I18n translation files
├── db/
│   ├── migrate/            # PostgreSQL migrations
│   ├── structure.sql       # DB schema dump
│   ├── jobs_structure.sql  # GoodJob schema
│   └── seeds.rb            # Seed data
├── lib/
│   ├── irida/              # Core Irida library modules
│   │   ├── auth.rb         # API scope constants
│   │   ├── pipelines.rb    # Pipeline registry singleton
│   │   ├── pipeline.rb     # Pipeline model
│   │   └── search_syntax/  # Advanced search parsing
│   ├── integrations/
│   │   └── ga4gh_wes_api/  # GA4GH WES API client (workflow submission)
│   ├── constraints/        # Rails route constraints
│   ├── progress_bar_stream.rb
│   └── tasks/              # Custom Rake tasks
├── test/                   # Minitest test suite
│   ├── system/             # Capybara system tests
│   ├── controllers/        # Controller tests
│   ├── models/             # Model unit tests
│   ├── services/           # Service unit tests
│   ├── policies/           # Policy unit tests
│   ├── components/         # ViewComponent tests
│   ├── graphql/            # GraphQL query/mutation tests
│   ├── jobs/               # Job tests
│   ├── integration/        # Integration tests
│   └── fixtures/           # YAML fixtures + test files
├── vendor/javascript/      # Vendored JS dependencies
├── Gemfile                 # Ruby dependencies
├── package.json            # JS dependencies (pnpm)
├── Dockerfile
└── devenv.nix              # Nix dev environment
```

## Directory Purposes

**`app/components/`:**

- Purpose: ViewComponent-based UI components; replaces complex partials
- Contains: Ruby class + paired `.html.erb` template per component
- Key subdirectories:
  - `viral/` — design system primitives (`Card`, `Dialog`, `DataTable`, `Dropdown`, `Form`, `Pagy`, `SortableList`)
  - Domain components: `samples/`, `groups/`, `workflow_executions/`, `activities/`, `attachments/`, `members/`, `metadata_templates/`, `layout/`
- Versioned components use `v1/`, `v2/` subdirs (e.g. `app/components/viral/dropdown/v1/`)

**`app/controllers/concerns/`:**

- Purpose: Mixins shared across multiple controllers
- Key files:
  - `app/controllers/concerns/list_actions.rb` — paginated list handling
  - `app/controllers/concerns/storable.rb` — persisting UI state
  - `app/controllers/concerns/workflow_execution_actions.rb` — shared workflow actions
  - `app/controllers/concerns/metadata.rb` — metadata CRUD actions
  - `app/controllers/concerns/sessionless_authentication.rb` — PAT/token auth

**`app/models/concerns/`:**

- Purpose: Model mixins for shared behavior
- Key files:
  - `app/models/concerns/has_puid.rb` — persistent unique IDs (e.g. `SAM-001`)
  - `app/models/concerns/routable.rb` — full_path, abbreviated_path helpers
  - `app/models/concerns/history.rb` — Logidze-based version history
  - `app/models/concerns/track_activity.rb` — PublicActivity integration
  - `app/models/concerns/metadata_sortable.rb` — metadata sorting

**`app/services/`:**

- Purpose: All business logic; one service = one operation
- Base classes:
  - `app/services/base_service.rb` — root base
  - `app/services/base_group_service.rb`, `base_project_service.rb`, `base_sample_service.rb`, `base_workflow_execution_service.rb`
- Pattern: `SomeNamespace::CreateService`, `::UpdateService`, `::DestroyService`, `::TransferService`

**`lib/irida/`:**

- Purpose: Core application library (not AR models)
- Key files:
  - `lib/irida/pipelines.rb` — singleton pipeline registry
  - `lib/irida/pipeline.rb` — pipeline model (read from config YAML)
  - `lib/irida/auth.rb` — API scope constants (`API_SCOPE`, `READ_API_SCOPE`)

**`lib/integrations/ga4gh_wes_api/`:**

- Purpose: HTTP client for GA4GH Workflow Execution Service API (workflow submission/status)
- Used by: `WorkflowExecutionSubmissionJob`, `WorkflowExecutionStatusJob`

**`config/pipelines/`:**

- Purpose: Pipeline definition YAML files loaded by `Irida::Pipelines` singleton
- New pipelines added here become available in the workflow execution UI

**`config/routes/`:**

- Purpose: Split route files loaded via `draw :name` in `config/routes.rb`
- Files: `group.rb`, `project.rb`, `api.rb`, `dashboard.rb`, `profile.rb`, `user.rb`, `workflow_executions.rb`, `activities.rb`, `system.rb`, `development.rb`

## Key File Locations

**Entry Points:**

- `config/routes.rb`: Root router, delegates to `config/routes/*.rb`
- `app/controllers/application_controller.rb`: Base controller (auth, locale, error handling)
- `app/graphql/irida_schema.rb`: GraphQL schema root

**Configuration:**

- `config/initializers/`: Rails initializers (Devise, GoodJob, etc.)
- `config/pipelines/`: Pipeline YAML definitions
- `config/schemas/workflow_execution_metadata.json`: JSON schema for WE metadata validation

**Core Logic:**

- `app/models/namespace.rb`: Central Namespace STI base model
- `app/models/sample.rb`: Sample model with metadata jsonb
- `app/models/workflow_execution.rb`: Workflow execution state machine
- `app/services/base_service.rb`: Service base class
- `app/policies/application_policy.rb`: Authorization base class
- `lib/irida/pipelines.rb`: Pipeline registry singleton

**Testing:**

- `test/` root with mirrored structure to `app/`
- `test/fixtures/`: YAML fixture files
- `test/system/`: Capybara browser-level tests
- `test/test_helpers/`: Shared test helper modules

## Naming Conventions

**Files:**

- Controllers: `snake_case_controller.rb` (e.g. `samples_controller.rb`)
- Services: `snake_case_service.rb` under domain namespace dir (e.g. `services/projects/samples/create_service.rb`)
- Components: `snake_case_component.rb` + `snake_case_component.html.erb` pairs
- Jobs: `snake_case_job.rb` (e.g. `workflow_execution_submission_job.rb`)
- Policies: `resource_name_policy.rb` (e.g. `sample_policy.rb`)
- GraphQL mutations: `verb_noun.rb` (e.g. `create_sample.rb`, `transfer_samples.rb`)

**Directories:**

- Domain: `snake_case/` matching model namespace (e.g. `workflow_executions/`)
- Component versioning: `v1/`, `v2/` for breaking design system changes
- Nested resources mirror URL structure (e.g. `controllers/projects/samples/metadata/`)

**Classes:**

- Services: `Namespace::VerbService` (e.g. `Samples::CreateService`, `WorkflowExecutions::SubmissionService`)
- Components: `Domain::NameComponent` (e.g. `Viral::Card::HeaderComponent`)
- Jobs: `VerbNounJob` or `NounVerbJob` (e.g. `WorkflowExecutionSubmissionJob`)
- Policies: `ResourcePolicy` (e.g. `NamespacePolicy`, `SamplePolicy`)

## Where to Add New Code

**New Feature (domain operation):**

- Service: `app/services/[domain]/[verb]_service.rb` inheriting appropriate base service
- Controller action: `app/controllers/[domain]_controller.rb` or nested `app/controllers/[parent]/[domain]_controller.rb`
- Policy method: `app/policies/[resource]_policy.rb`
- Route: `config/routes/[domain].rb`
- Views: `app/views/[domain]/[action].html.erb`
- Tests: `test/services/[domain]/[verb]_service_test.rb`, `test/controllers/[domain]_controller_test.rb`

**New GraphQL Mutation:**

- Mutation class: `app/graphql/mutations/[verb_noun].rb` inheriting `BaseMutation`
- Register in: `app/graphql/types/mutation_type.rb`
- Test: `test/graphql/mutations/[verb_noun]_test.rb`

**New ViewComponent:**

- Class: `app/components/[domain]/[name]_component.rb`
- Template: `app/components/[domain]/[name]_component.html.erb`
- Test: `test/components/[domain]/[name]_component_test.rb`

**New Background Job:**

- Class: `app/jobs/[domain]/[verb]_job.rb` inheriting `ApplicationJob`
- Test: `test/jobs/[domain]/[verb]_job_test.rb`

**New Pipeline:**

- YAML config: `config/pipelines/[pipeline_name].yml`
- Loaded automatically by `Irida::Pipelines` singleton

**Utilities / Shared Lib:**

- Ruby lib module: `lib/irida/[name].rb`
- External API client: `lib/integrations/[service_name]/`

## Special Directories

**`app/assets/builds/tailwind/`:**

- Purpose: Compiled Tailwind CSS output
- Generated: Yes
- Committed: No (gitignored)

**`app/assets/svg/icons/`:**

- Purpose: SVG icon files (Heroicons + Phosphor variants)
- Generated: No
- Committed: Yes

**`db/migrate/`:**

- Purpose: PostgreSQL migration files
- Generated: No (authored)
- Committed: Yes

**`db/jobs_migrate/`:**

- Purpose: GoodJob background job queue migrations
- Generated: No
- Committed: Yes

**`coverage/`:**

- Purpose: SimpleCov test coverage reports
- Generated: Yes
- Committed: No

**`tmp/`:**

- Purpose: Rails tmp (cache, pids, sockets)
- Generated: Yes
- Committed: No

**`vendor/javascript/`:**

- Purpose: Vendored JavaScript dependencies (importmap)
- Generated: No
- Committed: Yes

---

_Structure analysis: 2026-03-08_
