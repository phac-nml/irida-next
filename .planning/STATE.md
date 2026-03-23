---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: Completed 01-02-PLAN.md (Flipper flag, POST /query route, query_v2 controller action)
last_updated: "2026-03-23T18:29:37.436Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-21)

**Core value:** Researchers can find samples, run workflows, and export data reliably — with a fast, accessible UI proven correct by a test suite that tests the right things at the right layer.
**Current focus:** Phase 01 — advanced-search-v2-backend

## Current Position

Phase: 01 (advanced-search-v2-backend) — EXECUTING
Plan: 1 of 2

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
| ----- | ----- | ----- | -------- |
| -     | -     | -     | -        |

**Recent Trend:**

- Last 5 plans: none yet
- Trend: -

_Updated after each plan completion_
| Phase 01 P01 | 35 | 2 tasks | 8 files |
| Phase 01-advanced-search-v2-backend P02 | 525699 | 2 tasks | 5 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- 7-PR sequential strategy for Advanced Search V2 (backend-first)
- Server round-trip for V2 query builder state (avoids DOM manipulation)
- V1/V2 parallel namespace — no shared code, zero disruption
- Test refactor T1-T6 ladder is strictly sequential (shared test file conflicts)
- Data grid keyboard nav is standalone PR-K1 (isolated from cursor/pagination work)
- [Phase 01]: Sample::V2 namespace uses module constant on Sample class (not module nesting) due to Sample being a class, matching Sample::Query pattern
- [Phase 01]: Pagy::Method #request provided as minimal hash {params: {}} in Query PORO since pagination params injected directly
- [Phase 01-advanced-search-v2-backend]: query_v2 action decomposed into private helpers to satisfy RuboCop Metrics thresholds
- [Phase 01-advanced-search-v2-backend]: Explicit Flipper.enable in flag-on controller tests guards against test-isolation side effects from flag-off tests

### Dependency Gates

- Phase 1 is BLOCKED until PR #1659 (query tree value objects) is merged
- Phase 4 is BLOCKED until PR #1609 (T1: members + group-links sort migration) is merged
- Phase 6 has NO blocking dependency — can start any time

### Pending Todos

None yet.

### Blockers/Concerns

- PR #1659 must merge before Phase 1 work begins (query tree value objects + serializer + migrator)
- PR #1609 must merge before Phase 4 work begins (T1 members + group-links sorting migration)

## Session Continuity

Last session: 2026-03-23T18:29:37.434Z
Stopped at: Completed 01-02-PLAN.md (Flipper flag, POST /query route, query_v2 controller action)
Resume file: None
