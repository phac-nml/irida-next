# Requirements: IRIDA Next Active Milestone

**Defined:** 2026-03-22
**Core Value:** Researchers can find samples and run workflows reliably — with a fast, accessible UI proven correct by a test suite that tests the right things at the right layer.

## v1 Requirements

### Advanced Search V2

- [x] **ASV2-01**: V2 executor translates GroupNode/ConditionNode trees into Arel SQL queries
- [x] **ASV2-02**: V2 search is gated behind a Flipper feature flag — V1 remains fully functional when flag is off
- [x] **ASV2-03**: Controller integrates V2 executor when flag is on; routes and params are versioned
- [ ] **ASV2-04**: Right-side drawer component renders the query builder UI
- [ ] **ASV2-05**: Filter bar shows active query summary and drawer toggle button
- [ ] **ASV2-06**: Stimulus controller allows users to add, remove, and reorder query conditions in the drawer
- [ ] **ASV2-07**: Turbo frame updates sample list results live as query changes (no full page reload)
- [ ] **ASV2-08**: Active query state is reflected in the URL for shareable/bookmarkable searches
- [ ] **ASV2-09**: Polish pass: analytics events, accessibility audit, V1 deprecation flag set
- [ ] **ASV2-10**: All V2 code has test coverage (model, component, system) and V1 tests still pass

### Test Suite Refactor

- [ ] **TST-01**: Workflow executions table sort assertions moved from system to controller tests (T2)
- [ ] **TST-02**: Groups samples sort/persistence semantics moved to controller/model tests (T3)
- [ ] **TST-03**: Projects samples sort/persistence semantics moved to controller/model tests (T4)
- [ ] **TST-04**: Remaining samples query-state assertions (filter/limit/page/session) moved to lower layer (T5)
- [ ] **TST-05**: sleep, execute_script, and wait:10+ flake points removed or replaced with deterministic patterns (T6)

### Data Exports

- [ ] **DEX-01**: Backend queue lifecycle for linelist exports (enqueue, status transitions, error handling)
- [ ] **DEX-02**: GraphQL control plane for export job status (query + mutation)
- [ ] **DEX-03**: Frontend polling component shows live job status and progress
- [ ] **DEX-04**: Completed exports are downloadable; failed exports surface actionable errors
- [ ] **DEX-05**: Stale/completed export jobs are cleaned up automatically

### Data Grid

- [ ] **DGR-01**: Arrow key navigation moves focus between cells in the data grid (row and column)
- [ ] **DGR-02**: Focus management follows treegrid ARIA pattern (aria-rowindex, aria-colindex, roving tabindex)
- [ ] **DGR-03**: Keyboard navigation is compatible with existing mouse/touch interaction and selection behavior

## v2 Requirements

### Advanced Search V2

- **ASV2-V2-01**: Saved search queries (user-defined presets)
- **ASV2-V2-02**: V1 modal fully removed from codebase (post-deprecation cleanup)

### Test Suite Refactor

- **TST-V2-01**: Pathogen test ownership migration to Pathogen project test suite

### Data Grid

- **DGR-V2-01**: Cursor-based pagination follow-up after keyboard nav lands
- **DGR-V2-02**: Virtual scrolling for very large datasets

## Out of Scope

| Feature                                              | Reason                                |
| ---------------------------------------------------- | ------------------------------------- |
| Toaster / status messaging                           | Deferred — not in this milestone      |
| Layout sidebar                                       | Deferred — not in this milestone      |
| Pathogen CSS migration                               | Blocked on extraction cutover (#1598) |
| Pathogen datepicker                                  | Blocked on extraction + CSS baseline  |
| OAuth / auth changes                                 | Not relevant to current milestone     |
| Advanced Search V2 real-time collaborative filtering | Over-engineered for v1                |

## Traceability

| Requirement | Phase                                              | Status   |
| ----------- | -------------------------------------------------- | -------- |
| ASV2-01     | Phase 1 — Advanced Search V2 Backend               | Complete |
| ASV2-02     | Phase 1 — Advanced Search V2 Backend               | Complete |
| ASV2-03     | Phase 1 — Advanced Search V2 Backend               | Complete |
| ASV2-04     | Phase 2 — Advanced Search V2 UI Layer              | Pending  |
| ASV2-05     | Phase 2 — Advanced Search V2 UI Layer              | Pending  |
| ASV2-06     | Phase 2 — Advanced Search V2 UI Layer              | Pending  |
| ASV2-07     | Phase 3 — Advanced Search V2 Live Results + Polish | Pending  |
| ASV2-08     | Phase 3 — Advanced Search V2 Live Results + Polish | Pending  |
| ASV2-09     | Phase 3 — Advanced Search V2 Live Results + Polish | Pending  |
| ASV2-10     | Phase 3 — Advanced Search V2 Live Results + Polish | Pending  |
| TST-01      | Phase 4 — Test Suite Refactor                      | Pending  |
| TST-02      | Phase 4 — Test Suite Refactor                      | Pending  |
| TST-03      | Phase 4 — Test Suite Refactor                      | Pending  |
| TST-04      | Phase 4 — Test Suite Refactor                      | Pending  |
| TST-05      | Phase 4 — Test Suite Refactor                      | Pending  |
| DEX-01      | Phase 5 — Data Exports                             | Pending  |
| DEX-02      | Phase 5 — Data Exports                             | Pending  |
| DEX-03      | Phase 5 — Data Exports                             | Pending  |
| DEX-04      | Phase 5 — Data Exports                             | Pending  |
| DEX-05      | Phase 5 — Data Exports                             | Pending  |
| DGR-01      | Phase 6 — Data Grid Keyboard Navigation            | Pending  |
| DGR-02      | Phase 6 — Data Grid Keyboard Navigation            | Pending  |
| DGR-03      | Phase 6 — Data Grid Keyboard Navigation            | Pending  |

**Coverage:**

- v1 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0 ✓

---

_Requirements defined: 2026-03-22_
_Last updated: 2026-03-22 after roadmap creation_
