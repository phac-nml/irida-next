# Codebase Concerns

**Analysis Date:** 2026-03-08

## Tech Debt

**`deferred_samplesheet` Feature Flag Not Retired:**

- Issue: The `:deferred_samplesheet` Flipper flag controls dual code paths across multiple layers. Old code paths are explicitly marked for removal once the flag is retired but remain active.
- Files: `app/models/concerns/file_selector.rb` (lines 7–93 "TODO START/END" block, lines 138–165), `app/controllers/workflow_executions/submissions_controller.rb`, `app/controllers/workflow_executions/file_selector_controller.rb`, `app/controllers/workflow_executions/metadata_controller.rb`
- Impact: Dead code accumulation, parallel method pairs (`_with_feature_flag` / `_without_feature_flag`) increase cognitive overhead and test surface. Risk of old path being accidentally invoked.
- Fix approach: Enable flag globally, delete all `_without_feature_flag` methods and surrounding branches, rename `_with_feature_flag` variants to their canonical names, retire the flag from Flipper.

**Multiple Un-retired Feature Flags:**

- Issue: At least 6 Flipper flags have accrued in production code (`deferred_samplesheet`, `samples_refresh_notice`, `data_grid_samples_table`, `v2_dropdown`, `compose_with_retry`, `wes_extended_metadata`, `integration_access_token_generation`). Each adds a conditional branch that must be tested in both states.
- Files: `app/models/concerns/file_selector.rb`, `app/models/project.rb`, `app/controllers/integration_access_token_controller.rb`, `app/controllers/workflow_executions_controller.rb`, `app/components/samples/table_component.rb`, `app/components/viral/dropdown_component.rb`, `app/helpers/blob_helper.rb`, `app/services/base_sample_service.rb`, `app/services/workflow_executions/create_service.rb`
- Impact: Test matrix complexity grows with each flag. Old UI variants (`v1_dropdown`) persist in production.
- Fix approach: Audit each flag's rollout state, retire flags that are 100% on, delete dead branches.

**`Members::UpdateService` Passes All Params:**

- Issue: `TODO: Update params to only keep required values` in the `initialize` method means the service accepts an unfiltered params hash.
- Files: `app/services/members/update_service.rb:11`
- Impact: Risk of mass-assignment of unintended attributes via `member.update(params)` at line 30.
- Fix approach: Whitelist only `access_level` and other explicitly needed keys before calling `member.update`.

**`WorkflowExecution::FieldConfiguration` Not Wired to UI:**

- Issue: Class built with documented TODO to integrate with `WorkflowExecutions::AdvancedSearchComponent` for dynamic enum dropdowns.
- Files: `app/models/workflow_execution/field_configuration.rb:9`
- Impact: Advanced search dropdowns for workflow executions must be kept in sync manually between the config class and the component.
- Fix approach: Connect `FieldConfiguration#enum_fields` output to the component's field-building logic.

**Workflow Execution Sort Inconsistency:**

- Issue: Documented TODO notes that the samples table uses a custom `SortComponent` while workflow executions use `Ransack::SortComponent`, creating two divergent patterns that cannot be unified without UI changes.
- Files: `app/controllers/concerns/workflow_execution_actions.rb:258`
- Impact: Developer friction when updating sorting behavior; visual/UX inconsistency.
- Fix approach: When updating the workflow executions UI, adopt the custom `SortComponent` used by the samples table.

**`DataExports::CreateJob` God Class:**

- Issue: 368-line job class handles all export types (sample, analysis, linelist), streaming, manifest generation, and zip assembly in one file with 4 Rubocop size suppressions.
- Files: `app/jobs/data_exports/create_job.rb`
- Impact: High cyclomatic complexity, hard to test individual export paths in isolation.
- Fix approach: Extract per-export-type strategy objects and a separate manifest builder.

**`Samples::TransferService` Oversized:**

- Issue: 456-line service with multiple Rubocop size suppressions handles locking, batch transfer, permissions, and activity logging in a single class.
- Files: `app/services/samples/transfer_service.rb`
- Impact: Difficult to extend or modify transfer logic without risking regressions in other paths.
- Fix approach: Extract lock-acquisition, batch-transfer, and activity-logging into separate collaborator objects.

**`Namespace` God Model:**

- Issue: 598-line model with extensive raw Arel queries (`self_and_ancestors`, `self_and_descendants`), metadata summary SQL generation, and STI polymorphism all in one class with a `# rubocop:disable Metrics/ClassLength` suppressor.
- Files: `app/models/namespace.rb`
- Impact: Any change to ancestry, routing, or metadata logic risks unintended side-effects in the other concerns. The complex Arel queries are fragile under ORM upgrades.
- Fix approach: Extract ancestry querying to a dedicated `NamespaceAncestry` query object; extract metadata summary SQL to a dedicated service.

**Pervasive Rubocop Metric Suppressions:**

- Issue: 422 `rubocop:disable` comments in `app/`, dominated by `Metrics/MethodLength` (122), `Metrics/AbcSize` (96), `Metrics/ParameterLists` (35), and `Metrics/ClassLength` (33).
- Files: Across `app/services/`, `app/controllers/`, `app/models/`, `app/jobs/`
- Impact: Rubocop is effectively silenced as a complexity signal; new contributors have no enforced size guidance.
- Fix approach: Don't add new suppressions; incrementally refactor hotspots when touching affected files.

## Security Considerations

**`Members::UpdateService` Unfiltered Params to `member.update`:**

- Risk: If controller passes a broader params hash (unverified), attributes beyond `access_level` could be set.
- Files: `app/services/members/update_service.rb:30`
- Current mitigation: Controller strong params should filter upstream; Rails `attr_accessible` is not used.
- Recommendations: Explicitly whitelist in the service `initialize` as the TODO states.

**GraphQL Controller CSRF/Session Bypass:**

- Risk: `skip_before_action :authenticate_user!` and `skip_forgery_protection with: :null_session` are intentional for API access, but unauthenticated users reach the execute action before `authenticate_sessionless_user!` runs.
- Files: `app/controllers/graphql_controller.rb:8,16,19`
- Current mitigation: `SessionlessAuthentication` sets `current_user` from bearer token; public data is allowed by policy.
- Recommendations: Verify all mutations are policy-guarded; `graphiql-rails` endpoint must be disabled in production (confirm in config).

**`json_string_to_hash` Regex-Based JSON Normalization:**

- Risk: `JSON.parse json_string.gsub('=>', ':')` is a fragile Ruby-hash-to-JSON conversion. If the string contains `=>` inside a value, it will corrupt the value.
- Files: `app/helpers/json_helper.rb:8`
- Current mitigation: Only called for specific legacy data display.
- Recommendations: Replace with `eval`-safe structured conversion or avoid storing Ruby hash syntax in the DB.

**`html_safe` Raw HTML in View Helper:**

- Risk: `doc.to_html.html_safe` marks parsed HTML as safe without per-field sanitization.
- Files: `app/helpers/view_helper.rb:56` (suppressed by `# rubocop:disable Rails/OutputSafety`)
- Current mitigation: Input is passed through a parser (`doc`) before calling `html_safe`.
- Recommendations: Confirm the parser strips `<script>` and event attributes; add explicit `ActionView::Helpers::SanitizeHelper.sanitize` before `html_safe`.

**Git-Pinned `azure-blob` Gem on Custom Branch:**

- Risk: `gem 'azure-blob', github: 'phac-nml/azure-blob', branch: 'put-blob-from-url_single_and_multiple'` pins to a non-released, org-forked branch with no version tag.
- Files: `Gemfile:111`
- Current mitigation: None — branch commits can change without a version bump.
- Recommendations: Upstream the custom changes, pin to a release tag, or publish a versioned fork.

## Performance Bottlenecks

**`Namespace#validate_nesting_level` Queries on Every Create/Reparent:**

- Problem: `parent.ancestors.count` fires a DB query inside a validation callback triggered on every `new_record?` or `parent_id_changed?` save.
- Files: `app/models/namespace.rb:554`
- Cause: `ancestors` is a relation that triggers a COUNT query with path-prefix matching on the routes table.
- Improvement path: Cache ancestor count on the namespace record; or use a denormalized `depth` integer column updated via trigger.

**`file_selector.rb` Legacy `sort_files` Loads All Attachments into Memory:**

- Problem: `sort_files` iterates all non-reverse attachments in Ruby, building arrays of hashes. This runs for every sample in file selector contexts.
- Files: `app/models/concerns/file_selector.rb:14–34`
- Cause: Ruby-side sorting of DB results; no SQL-level LIMIT.
- Improvement path: This code path is retired when `deferred_samplesheet` is enabled. Retiring the flag eliminates the bottleneck entirely.

**`query_files_by_pattern` Uses DB-Level Regex:**

- Problem: `ActiveStorage::Blob.arel_table[:filename].matches_regexp(pattern)` pushes an arbitrary regex to PostgreSQL for every file selector or pattern-based file query.
- Files: `app/models/concerns/file_selector.rb:223`
- Cause: No index on `active_storage_blobs.filename`; full sequential scan for pattern matching.
- Improvement path: Add a `pg_trgm` GIN index on `filename`; or pre-classify file formats at upload time and query the `metadata->>'format'` JSONB field instead.

**`Attachments::CreateService` Loops `@attachments.each(&:save)`:**

- Problem: Each attachment is saved individually inside a transaction, firing one `INSERT` per attachment.
- Files: `app/services/attachments/create_service.rb:44`
- Cause: Using `each(&:save)` instead of `insert_all` or batch-save strategies.
- Improvement path: Collect valid attachments and use `Attachment.insert_all` for bulk inserts (note: skips callbacks — evaluate if `create_activities` must run per-record).

**Artificial 1-Second Job Delays:**

- Problem: `Samples::TransferJob`, `Samples::CloneJob`, and spreadsheet import jobs are enqueued with `wait_until: 1.second.from_now`.
- Files: `app/controllers/samples/transfers_controller.rb:24`, `app/controllers/samples/clones_controller.rb:19`, `app/controllers/concerns/metadata_spreadsheet_import_actions.rb:21`, `app/controllers/concerns/sample_spreadsheet_import_actions.rb:21`
- Cause: Likely added to allow Turbo stream response to render before job starts. This is a timing-based workaround.
- Improvement path: Use a Turbo-native loading indicator instead of a timing hack; the 1-second delay is not reliable under load.

## Fragile Areas

**`TrackActivity` Broad `rescue StandardError` Silencing:**

- Files: `app/models/concerns/track_activity.rb:165,172`
- Why fragile: Exceptions from `acts_as_paranoid`-missing models are silently swallowed. If a model is refactored to remove soft-delete without updating activity tracking, the failure is invisible.
- Safe modification: Add explicit `# :nocov:` annotations and log the rescue as a warning, not silent swallow.
- Test coverage: Skipped in `test/models/metadata_template_test.rb:79` — "TrackActivity concern is not yet implemented."

**`Route#rename_descendants` Callback on Every Route Update:**

- Files: `app/models/route.rb:14`
- Why fragile: `after_update :rename_descendants` triggers bulk route path updates on any route change. If parent path changes cascade through deep namespace trees, this fires a potentially large batch of recursive updates.
- Safe modification: Always test with at least 3 levels of nesting; add explicit transaction wrapping and guard against partial failures.
- Test coverage: No dedicated performance test for deep hierarchies.

**`WorkflowExecution#send_email` in `after_save` Callback:**

- Files: `app/models/workflow_execution.rb:14,41`
- Why fragile: Email delivery is triggered synchronously in an `after_save` callback conditioned on `saved_change_to_state?`. If the mailer fails, the save transaction may roll back or the error is swallowed depending on the delivery method.
- Safe modification: Move email dispatch to a dedicated `after_commit` callback or an explicit job enqueue in the service layer.
- Test coverage: Covered by system tests; unit coverage of edge states (cancelled mid-run) unknown.

**`pathogen_view_components` Pinned to Git `main` Branch:**

- Files: `Gemfile:67`
- Why fragile: `branch: 'main'` means any upstream commit to the external repo can silently change component behavior after `bundle update`.
- Safe modification: Pin to a specific commit SHA or version tag. Update deliberately.
- Test coverage: Component tests exist (`test/components/`) but only for locally-defined components; upstream regressions go undetected until runtime.

**`AdvancedSearch::Form#constantize` Dynamic Class Resolution:**

- Files: `app/models/concerns/advanced_search/form.rb:33,39`
- Why fragile: `self.class.name.deconstantize.constantize::SearchGroup` and `::SearchCondition` dynamically resolve classes by naming convention. A rename or namespace change silently produces `NameError` at runtime.
- Safe modification: Make the associated class names explicit constants or pass them as constructor arguments.

## Test Coverage Gaps

**`TrackActivity` Concern Untested:**

- What's not tested: The `get_object_by_id`, `get_object_by_puid`, and `transfer_activity_parameters` methods in `TrackActivity`.
- Files: `app/models/concerns/track_activity.rb`, `test/models/metadata_template_test.rb:79` (explicitly skipped)
- Risk: Silent data corruption in activity logs on namespace transfers or deletions goes undetected.
- Priority: High

**GraphQL Mutation Authorization Not Independently Tested:**

- What's not tested: `authorize!` is called in service layer (not controllers), and GraphQL resolvers/mutations themselves don't call `authorize!` directly. Only 3 GraphQL-specific test files exist vs. 74 app GraphQL files.
- Files: `app/graphql/` (74 files), `test/graphql/` (3 files + query/mutation tests)
- Risk: A new mutation or type could bypass policy checks; not caught until integration or system test.
- Priority: High

**Feature Flag Both-States Coverage Incomplete:**

- What's not tested: Only 26 test references to feature flag names across all test files for 7 active flags. Most tests run with default flag state only.
- Files: `test/` (grep: 26 hits for flag names)
- Risk: Retiring a flag or changing its default could silently break functionality that was only tested in the non-flag branch.
- Priority: Medium

**Sapporo Integration Tests Always Skipped:**

- What's not tested: GA4GH WES Sapporo integration end-to-end behavior.
- Files: `test/integration/sapporo/integration_sapporo_test.rb:24,59,127`
- Risk: The WES integration path is only covered by unit tests with mocked HTTP; real API contract changes go undetected.
- Priority: Medium

---

_Concerns audit: 2026-03-08_
