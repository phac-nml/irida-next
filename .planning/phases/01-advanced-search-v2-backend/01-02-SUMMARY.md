---
phase: 01-advanced-search-v2-backend
plan: 02
subsystem: api
tags: [rails, flipper, turbo-stream, controller, feature-flag, session]

# Dependency graph
requires:
  - phase: 01-advanced-search-v2-backend plan 01
    provides: "AdvancedSearch::V2::Serializer, Sample::V2::Query, AdvancedSearch::V2::Executor"
provides:
  - "Flipper flag :advanced_search_v2 registered in config/features.yml"
  - "POST /query route pointing to samples#query_v2"
  - "query_v2 controller action gated on Flipper flag"
  - "Project-scoped V2 session storage via store() not update_store()"
  - "Dedicated query_v2.turbo_stream.erb view (no @query dependency)"
  - "Controller tests for flag-on/flag-off/invalid-json scenarios"
affects: ["02-advanced-search-v2-frontend", "future V2 UI integration phases"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Flipper flag gate at top of action: return not_found unless Flipper.enabled?(:flag)"
    - "Private helper decomposition: build_v2_query / respond_to_v2_query / render_v2_turbo_stream"
    - "Project-scoped session key: :'#{controller_name}_#{project.id}_advanced_search_v2'"
    - "store() for JSON string session values — never update_store() which corrupts strings"
    - "Explicit Flipper.enable in flag-on tests to guard against test-isolation side effects from flag-off tests"

key-files:
  created:
    - app/views/projects/samples/query_v2.turbo_stream.erb
  modified:
    - config/features.yml
    - config/routes/project.rb
    - app/controllers/projects/samples_controller.rb
    - test/controllers/projects/samples_controller_test.rb

key-decisions:
  - "query_v2 action decomposed into private helpers (build_v2_query, respond_to_v2_query, render_v2_turbo_stream) to satisfy RuboCop Metrics thresholds"
  - "Test isolation: tests that need flag ON call Flipper.enable explicitly — flag-off test disables flag and subsequent tests must not rely on initializer auto-enable across test boundaries"
  - "enable_in_development: false for :advanced_search_v2 — flag is OFF in dev by default but ON in test (flipper.rb enables all flags in test env)"
  - "Flipper initializer enables ALL features in test env regardless of enable_in_development — flag-off tests must explicitly call Flipper.disable"

patterns-established:
  - "V2 controller action pattern: flag gate -> authorize -> build_v2_query -> respond_to_v2_query"
  - "Dedicated turbo_stream template per V2 action — do not share with V1 search.turbo_stream.erb"

requirements-completed: [ASV2-02, ASV2-03]

# Metrics
duration: 25min
completed: 2026-03-23
---

# Phase 01 Plan 02: V2 Controller Integration Summary

**Flipper-gated POST /query route with dedicated query_v2 controller action, project-scoped session storage, and V2 turbo stream response — V1 search/index/select untouched**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-23T18:30:00Z
- **Completed:** 2026-03-23T18:55:00Z
- **Tasks:** 2 (+ 1 TDD RED commit)
- **Files modified:** 5

## Accomplishments

- Registered `:advanced_search_v2` Flipper flag (enable_in_development: false, enabled in test env by initializer)
- Added `POST /query` route pointing to `samples#query_v2` via `action: :query_v2` (avoids conflict with V1 private `query` method)
- Implemented `query_v2` action: Flipper gate, Serializer.parse, Sample::V2::Query, project-scoped session store
- Created `query_v2.turbo_stream.erb` with no `@query` dependency
- All 25 controller tests pass; V1 model tests unaffected

## Task Commits

Each task was committed atomically:

1. **Task 1: Register Flipper flag and add route** - `5bf81acc8` (feat)
2. **Task 2 TDD RED: Failing controller tests** - `286a736ca` (test)
3. **Task 2 TDD GREEN+REFACTOR: Implement query_v2 action** - `2e56a24cb` (feat)

_Note: TDD task produced RED commit then combined GREEN+REFACTOR commit (refactor forced by RuboCop pre-commit hook)_

## Files Created/Modified

- `config/features.yml` - Added :advanced_search_v2 entry (enable_in_development: false)
- `config/routes/project.rb` - Added `post :query, action: :query_v2` in samples collection
- `app/controllers/projects/samples_controller.rb` - Added query_v2 public action + 3 private helpers + query_v2_session_key
- `app/views/projects/samples/query_v2.turbo_stream.erb` - Dedicated V2 turbo stream response (created)
- `test/controllers/projects/samples_controller_test.rb` - 3 new V2 tests (flag-off 404, flag-on 200, invalid JSON 422)

## Decisions Made

- Decomposed `query_v2` into private helpers (`build_v2_query`, `respond_to_v2_query`, `render_v2_turbo_stream`) to pass RuboCop Metrics checks (AbcSize/CyclomaticComplexity/MethodLength limits)
- Added explicit `Flipper.enable(:advanced_search_v2)` in flag-on tests — the flag-off test calls `Flipper.disable` and tests may run in any order; relying on initializer's auto-enable is insufficient for test isolation
- Used `store()` not `update_store()` for V2 session values — `update_store` merges hashes and would corrupt JSON strings

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test isolation: explicit Flipper.enable in flag-on tests**

- **Found during:** Task 2 TDD GREEN (first run)
- **Issue:** Tests for flag-on 200/422 returned 404 because flag-off test's `Flipper.disable` call persisted across tests when run before them
- **Fix:** Added `Flipper.enable(:advanced_search_v2)` at start of each flag-on test
- **Files modified:** test/controllers/projects/samples_controller_test.rb
- **Verification:** All 25 tests pass consistently regardless of run order
- **Committed in:** 2e56a24cb (Task 2 feat commit)

**2. [Rule 1 - Bug] RuboCop Metrics: decomposed query_v2 into private helpers**

- **Found during:** Task 2 GREEN commit (pre-commit hook)
- **Issue:** query_v2 violated AbcSize (33.53/20), CyclomaticComplexity (8/7), MethodLength (25/15), PerceivedComplexity (9/8)
- **Fix:** Extracted build_v2_query, respond_to_v2_query, render_v2_turbo_stream as private helpers
- **Files modified:** app/controllers/projects/samples_controller.rb
- **Verification:** bin/rubocop passes, all tests still pass
- **Committed in:** 2e56a24cb (Task 2 feat commit, GREEN+REFACTOR combined)

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correctness and CI compliance. No scope creep.

## Issues Encountered

- RuboCop pre-commit hook blocked initial commit — resolved by extracting private helpers before committing GREEN implementation

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- V2 controller endpoint is fully wired: POST /query -> query_v2 -> Serializer -> Sample::V2::Query -> turbo stream
- Flipper flag :advanced_search_v2 registered and OFF in dev (ON in test)
- Phase 1 backend complete: V2 executor model layer (01-01) + controller integration (01-02) ready for PR
- Next: Phase 2 (frontend query builder UI) can begin once Phase 1 PR merges

---

_Phase: 01-advanced-search-v2-backend_
_Completed: 2026-03-23_
