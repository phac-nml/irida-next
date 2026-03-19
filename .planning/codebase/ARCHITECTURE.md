# Architecture

**Analysis Date:** 2026-03-08

## Pattern Overview

**Overall:** Rails MVC with Service Layer + Policy-based Authorization + Dual API surface (REST/GraphQL)

**Key Characteristics:**

- Standard Rails MVC with a dedicated `app/services/` layer for business logic
- ActionPolicy gem drives authorization (not CanCan/Pundit) — all auth goes through `authorize!` calls
- Two parallel API surfaces: Turbo/Hotwire for browser, GraphQL for programmatic access
- Namespace hierarchy (STI) is the central organizing model: `Group > ProjectNamespace > UserNamespace`
- Background jobs drive all async work (workflow executions, data exports, cleanup)
- ViewComponent (`app/components/`) replaces partials for reusable UI

## Layers

**Controllers (`app/controllers/`):**

- Purpose: HTTP request handling, authentication gates, response formatting
- Location: `app/controllers/`
- Contains: Action methods, before_action hooks, Turbo Stream responders
- Depends on: Services, Models, Policies (via `authorize!`)
- Used by: Rails router, GraphQL controller

**Services (`app/services/`):**

- Purpose: All business logic, mutations to domain objects
- Location: `app/services/`
- Contains: Plain Ruby classes inheriting `BaseService`, each scoped to one operation (e.g. `Samples::CreateService`, `WorkflowExecutions::SubmissionService`)
- Depends on: Models, ActionPolicy (authorization check also in services via `authorize!`)
- Used by: Controllers, GraphQL mutations, background jobs
- Base class: `app/services/base_service.rb` — injects `current_user`, `params`; includes `ActionPolicy::Behaviour`

**Models (`app/models/`):**

- Purpose: ActiveRecord persistence, validations, associations, scopes
- Location: `app/models/`
- Contains: AR models, STI subclasses, model concerns
- Key hierarchy: `Namespace (STI)` → `Group`, `Namespaces::ProjectNamespace`, `Namespaces::UserNamespace`
- `Project` delegates name/path/puid to its `Namespaces::ProjectNamespace`
- `Sample` belongs_to `Project`; has jsonb `metadata` + `metadata_provenance` columns
- `WorkflowExecution` has enum `state` with 9 states (initial → completed/error/canceled)

**Policies (`app/policies/`):**

- Purpose: Authorization rules scoped to each resource type
- Location: `app/policies/`
- Contains: ActionPolicy-based policy classes (e.g. `NamespacePolicy`, `SamplePolicy`, `GroupPolicy`)
- All policies inherit `ApplicationPolicy < ActionPolicy::Base`
- Token-based auth supported via `authorize :token, optional: true`
- Used by: Controllers (`authorize!`), Services (`authorize!`), GraphQL types

**GraphQL API (`app/graphql/`):**

- Purpose: Programmatic API for external consumers
- Location: `app/graphql/`
- Schema: `app/graphql/irida_schema.rb` — `IridaSchema < GraphQL::Schema`
- Contains: Types, Mutations, Resolvers, Validators, Connections
- Uses `GraphQL::Dataloader` for batch loading
- Auth: Mutations inherit `BaseMutation`; policy enforcement mirrors controller layer
- Custom cursor pagination: `Connections::ActiveRecordCursorPaginateConnection`

**Background Jobs (`app/jobs/`):**

- Purpose: Async processing — workflow execution lifecycle, data exports, cleanup
- Location: `app/jobs/`
- Base class: `app/jobs/application_job.rb`
- Key job chain for workflows: `WorkflowExecutionPreparationJob` → `WorkflowExecutionSubmissionJob` → `WorkflowExecutionStatusJob` → `WorkflowExecutionCompletionJob` / `WorkflowExecutionCancelationJob`
- Parent class `WorkflowExecutionJob` provides shared state validation helpers

**ViewComponents (`app/components/`):**

- Purpose: Encapsulated, testable UI components (replaces complex partials)
- Location: `app/components/`
- Contains: Ruby component classes + paired `.html.erb` templates
- Design system: `Viral::` namespace (e.g. `Viral::Card::HeaderComponent`, `Viral::Dialog`, `Viral::DataTable`)
- Domain components: `Samples::`, `Groups::`, `WorkflowExecutions::`, etc.
- Versioning via subdirectories: `v1/`, `v2/` (e.g. `app/components/viral/dropdown/v1/`, `v2/`)

**JavaScript (`app/javascript/`):**

- Purpose: Client-side interactivity via Stimulus controllers
- Location: `app/javascript/controllers/`
- Contains: Stimulus JS controllers mirroring server-side domain structure
- Entry point: `app/javascript/controllers/index.js`

## Data Flow

**Browser Request (Turbo/HTML):**

1. Request hits `config/routes.rb` (split across `config/routes/*.rb` via `draw :group` etc.)
2. Controller `before_action` authenticates user (`authenticate_user!`), sets `Current.user`
3. Controller calls `authorize! resource, to: :action?` (ActionPolicy)
4. Controller delegates mutation to a `*Service.new(current_user, params).execute`
5. Service performs AR operations, broadcasts Turbo Streams if needed
6. Controller renders view or redirects with flash
7. View uses ViewComponents and Turbo Frames for partial updates

**GraphQL Request:**

1. POST to `/api/graphql` → `GraphqlController`
2. `IridaSchema.execute` is called with context including `token`
3. Resolver or Mutation is dispatched
4. Mutations delegate to same service layer (`*Service.new(user, params).execute`)
5. Response serialized as JSON

**Workflow Execution Lifecycle:**

1. User submits via `WorkflowExecutions::CreateService`
2. `WorkflowExecutionPreparationJob` assembles samplesheet, attaches inputs
3. `WorkflowExecutionSubmissionJob` calls GA4GH WES API (via `lib/integrations/ga4gh_wes_api/`)
4. `WorkflowExecutionStatusJob` polls for completion
5. `WorkflowExecutionCompletionJob` or `WorkflowExecutionCancelationJob` finalizes state
6. Email sent to submitter via mailer on state change

**State Management:**

- Server-side state: PostgreSQL via ActiveRecord
- Client-side reactive: Turbo Streams broadcast via ActionCable (`broadcasts_refreshes`, `broadcast_refresh_later_to`)
- Audit trail: Logidze gem (`has_logidze`) on key models; `PublicActivity` for activity feed
- Soft delete: `acts_as_paranoid` on Namespace, Sample, WorkflowExecution, Project

## Key Abstractions

**Namespace (STI hierarchy):**

- Purpose: Organizes all resources in a hierarchical tree using path-based routing
- Location: `app/models/namespace.rb`, `app/models/group.rb`, `app/models/namespaces/project_namespace.rb`, `app/models/namespaces/user_namespace.rb`
- Pattern: STI with `type` column; `Route` model stores full paths for ancestors/descendants queries
- Max nesting depth: 10 (`Namespace::MAX_ANCESTORS`)
- `metadata_summary` is a jsonb column aggregated up the namespace tree via Postgres advisory locks

**BaseService:**

- Purpose: Shared auth context for all business logic
- Location: `app/services/base_service.rb`
- Pattern: `initialize(user, params)`; includes `ActionPolicy::Behaviour`; subclasses implement `execute`
- Domain base classes: `BaseGroupService`, `BaseProjectService`, `BaseSampleService`, `BaseWorkflowExecutionService`

**Viral Component System:**

- Purpose: Internal design system of reusable UI components
- Location: `app/components/viral/`
- Pattern: `Viral::ComponentName` namespacing; versioned via `v1/`, `v2/` subdirs

**Policies:**

- Purpose: Centralized access control per resource
- Location: `app/policies/`
- Pattern: `ResourcePolicy < ApplicationPolicy`; scope-based queries for "what can this user see"
- Scopes enforce membership + group links + personal namespace access

## Entry Points

**Web Application:**

- Location: `config/routes.rb` (delegates to `config/routes/*.rb`)
- Root: `dashboard#index`
- Scope: `/-/` prefix for all modern global routes
- Auth: Devise via `authenticate_user!` in `ApplicationController`

**GraphQL API:**

- Location: `app/controllers/graphql_controller.rb`
- Endpoint: `POST /api/graphql`
- Schema: `app/graphql/irida_schema.rb`

**Background Jobs:**

- Location: `app/jobs/`
- Triggered by: Services, other jobs, scheduled via GoodJob

**ActionCable:**

- Location: `app/channels/application_cable/connection.rb`, `channel.rb`
- Used for: Turbo Stream broadcasts (workflow status, sample table refresh)

## Error Handling

**Strategy:** Rescue in controllers + GraphQL schema; services bubble errors via model validity

**Patterns:**

- `ActionPolicy::Unauthorized` → renders `shared/error/not_authorized` (HTTP 401) or GraphQL error
- `ActiveRecord::RecordNotFound` → `not_found` method renders `shared/error/not_found` (HTTP 404)
- `Pagy::RangeError` → redirect to page 1
- GraphQL: `rescue_from` blocks in `IridaSchema` translate exceptions to `GraphQL::ExecutionError`
- Services: return model with `errors` populated; callers check `.persisted?` or `.valid?`

## Cross-Cutting Concerns

**Logging:** Rails logger + Logidze audit trail on key models (`has_logidze`)
**Activity Tracking:** `PublicActivity` gem via `TrackActivity` concern (`app/models/concerns/track_activity.rb`)
**Validation:** ActiveRecord validations + custom validators in `app/validators/`; JSON schema validation for `WorkflowExecution#metadata`
**Authentication:** Devise (session-based) + Personal Access Tokens (sessionless via `Sessionless Authentication` concern)
**Authorization:** ActionPolicy throughout — controllers, services, and GraphQL mutations all call `authorize!`
**Internationalization:** `I18n.with_locale` around-action; locale from user preference or params
**Soft Deletes:** `acts_as_paranoid` on `Namespace`, `Project`, `Sample`, `WorkflowExecution`

---

_Architecture analysis: 2026-03-08_
