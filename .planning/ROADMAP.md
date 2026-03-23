# Roadmap: IRIDA Next — Active Milestone

## Overview

Four parallel improvement tracks deliver in sequence: Advanced Search V2 ships first (backend-to-UI in three phases), then the test suite refactor completes the sorting migration ladder, then data exports closes the backend-queue-to-download cycle, and finally the data grid gains full keyboard navigation. Each phase delivers a coherent, independently verifiable capability. V1 search and existing sort tests remain untouched until each superseding phase is proven.

## Phases

- [ ] **Phase 1: Advanced Search V2 — Backend** - V2 executor + feature flag + controller integration (PRs 2-3; depends on #1659)
- [ ] **Phase 2: Advanced Search V2 — UI Layer** - Drawer component + filter bar + Stimulus query builder (PRs 4-5)
- [ ] **Phase 3: Advanced Search V2 — Live Results + Polish** - Turbo live results + URL sync + analytics + V1 deprecation flag (PRs 6-7)
- [ ] **Phase 4: Test Suite Refactor** - Complete sorting migration + query-state migration + robustness hardening (T2-T6; depends on #1609)
- [ ] **Phase 5: Data Exports** - Backend queue lifecycle + GraphQL + frontend polling + download + cleanup (PR2-PR4)
- [ ] **Phase 6: Data Grid Keyboard Navigation** - Arrow-key focus management + treegrid ARIA + interaction compatibility (PR-K1)

## Phase Details

### Phase 1: Advanced Search V2 — Backend

**Goal**: V2 search is fully executable server-side and flag-gated, with V1 untouched
**Depends on**: PR #1659 merged (query tree value objects + serializer + migrator)
**Requirements**: ASV2-01, ASV2-02, ASV2-03
**Success Criteria** (what must be TRUE):

1. A V2 query tree (GroupNode/ConditionNode) is translated into correct Arel SQL and returns the expected sample rows
2. With the Flipper flag OFF, the application behaves identically to today — V1 search is unaffected
3. With the Flipper flag ON, the controller routes requests through the V2 executor and returns results
4. All V2 model and controller tests pass; no V1 tests are broken
   **Plans:** 1/2 plans executed
   Plans:

- [ ] 01-01-PLAN.md — V2 Executor + FieldConfiguration + TreeValidator + Sample::V2::Query (model layer)
- [ ] 01-02-PLAN.md — Flipper flag + route + controller action + controller tests (integration layer)

### Phase 2: Advanced Search V2 — UI Layer

**Goal**: Users can open the V2 drawer and construct a query with add/remove conditions
**Depends on**: Phase 1
**Requirements**: ASV2-04, ASV2-05, ASV2-06
**Success Criteria** (what must be TRUE):

1. A toggle button in the filter bar opens a right-side drawer showing the query builder
2. The filter bar displays a readable summary of the current active query
3. A user can add a new condition (field + operator + value) and see it appear in the drawer
4. A user can remove a condition and see it disappear from the drawer without a full page reload
   **Plans**: TBD

### Phase 3: Advanced Search V2 — Live Results + Polish

**Goal**: Query changes update sample results live; searches are shareable; V1 is flagged for deprecation
**Depends on**: Phase 2
**Requirements**: ASV2-07, ASV2-08, ASV2-09, ASV2-10
**Success Criteria** (what must be TRUE):

1. Changing a condition in the drawer updates the sample list without a full page reload
2. The URL reflects the active query so a copied link reproduces the same results
3. Analytics events fire on query execution and the V1 deprecation Flipper flag is wired
4. All V2 component and system tests pass; all V1 tests still pass
   **Plans**: TBD

### Phase 4: Test Suite Refactor

**Goal**: All table/list sort semantics are tested at the controller/model layer; system tests retain only essential UI journeys; flaky patterns removed
**Depends on**: PR #1609 merged (T1: members + group-links sorting migration)
**Requirements**: TST-01, TST-02, TST-03, TST-04, TST-05
**Success Criteria** (what must be TRUE):

1. Workflow execution sort assertions exist in controller tests and the corresponding system sort tests are removed
2. Groups and projects samples sort/persistence semantics have controller/model coverage and the system sort tests are removed
3. Remaining samples query-state assertions (filter/limit/page/session) live at controller or model layer
4. The system test suite contains no sleep calls, no execute_script flake points, and no wait:10+ assertions that previously caused intermittent failures
   **Plans**: TBD

### Phase 5: Data Exports

**Goal**: Users can request a linelist export, monitor its progress, download the result, and stale jobs are cleaned up automatically
**Depends on**: Phase 4 (parallel-safe; can begin after Phase 3 if unblocked)
**Requirements**: DEX-01, DEX-02, DEX-03, DEX-04, DEX-05
**Success Criteria** (what must be TRUE):

1. Submitting a linelist export enqueues a background job and the job transitions through pending → processing → complete (or failed) states
2. A GraphQL query returns current job status and a mutation can cancel an in-progress export
3. The frontend polling component updates the job status display without requiring a page reload
4. A completed export shows a download link; a failed export shows an actionable error message
5. Export jobs older than the retention window are cleaned up automatically without user intervention
   **Plans**: TBD

### Phase 6: Data Grid Keyboard Navigation

**Goal**: Users can navigate the data grid entirely by keyboard, following the treegrid ARIA pattern, without breaking existing mouse/touch behavior
**Depends on**: Nothing (parallel-safe; can run alongside any phase)
**Requirements**: DGR-01, DGR-02, DGR-03
**Success Criteria** (what must be TRUE):

1. Arrow keys move focus between cells (up/down changes row, left/right changes column)
2. Focused cells have correct aria-rowindex, aria-colindex, and roving tabindex attributes matching the treegrid ARIA spec
3. Clicking a cell with a mouse and then using arrow keys continues navigating from the clicked cell
   **Plans**: TBD

## Progress

**Execution Order:** 1 → 2 → 3 → 4 → 5 → 6

| Phase                                         | Plans Complete | Status      | Completed |
| --------------------------------------------- | -------------- | ----------- | --------- |
| 1. Advanced Search V2 — Backend               | 1/2            | In Progress |           |
| 2. Advanced Search V2 — UI Layer              | 0/TBD          | Not started | -         |
| 3. Advanced Search V2 — Live Results + Polish | 0/TBD          | Not started | -         |
| 4. Test Suite Refactor                        | 0/TBD          | Not started | -         |
| 5. Data Exports                               | 0/TBD          | Not started | -         |
| 6. Data Grid Keyboard Navigation              | 0/TBD          | Not started | -         |
