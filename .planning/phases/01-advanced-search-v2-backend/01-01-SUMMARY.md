---
phase: 01-advanced-search-v2-backend
plan: "01"
subsystem: advanced-search
tags: [backend, arel, query-tree, tdd, pagy]
dependency_graph:
  requires:
    - app/models/advanced_search/v2/tree/group_node.rb
    - app/models/advanced_search/v2/tree/condition_node.rb
    - app/models/concerns/advanced_search/filtering.rb
    - app/models/concerns/advanced_search/operators.rb
  provides:
    - app/models/advanced_search/v2/executor.rb
    - app/models/advanced_search/v2/field_configuration.rb
    - app/validators/advanced_search/v2/tree_validator.rb
    - app/models/sample/v2/query.rb
  affects:
    - Future V2 controller (Plan 02) — consumes Sample::V2::Query
tech_stack:
  added: []
  patterns:
    - Visitor pattern for recursive tree walking (visit_group / visit_condition)
    - PORO query object composing executor + validator + pagination
    - TDD (tests written before implementation)
key_files:
  created:
    - app/models/advanced_search/v2/field_configuration.rb
    - app/models/advanced_search/v2/executor.rb
    - app/validators/advanced_search/v2/tree_validator.rb
    - app/models/sample/v2/query.rb
    - test/models/advanced_search/v2/field_configuration_test.rb
    - test/models/advanced_search/v2/executor_test.rb
    - test/validators/advanced_search/v2/tree_validator_test.rb
    - test/models/sample/v2/query_test.rb
  modified: []
decisions:
  - Sample::V2 is a module constant on the Sample class (not module nesting) because Sample is a class; uses class-notation with Style/ClassAndModuleChildren disable
  - Pagy::Method requires #request method; provided minimal hash {params: {}} since pagination params injected directly via #results arguments
  - Pagy::Offset (not Pagy base class) is returned by pagy(); test uses assert_kind_of Pagy
  - TreeValidator extracts validate_condition_field / validate_condition_operator / validate_array_value helpers to satisfy rubocop Metrics/AbcSize
metrics:
  duration: 35 minutes
  completed_date: "2026-03-23"
  tasks_completed: 2
  files_created: 8
  tests_added: 28
---

# Phase 01 Plan 01: V2 Executor, FieldConfiguration, TreeValidator, Query Summary

**One-liner:** V2 search executor layer — FieldConfiguration (field/operator constraints), TreeValidator (structural validation), Executor (Arel tree-walker via Operators+Filtering concerns), and Sample::V2::Query (PORO composing executor + pagination).

## What Was Built

### Task 1: Executor, FieldConfiguration, TreeValidator

**FieldConfiguration** — standalone class (no V1 inheritance) defining:

- `CORE_FIELDS`: name/puid (string), created_at/updated_at/attachments_updated_at (date)
- `STRING_OPERATORS`, `DATE_OPERATORS`, `METADATA_OPERATORS` constants
- `.valid_field?`, `.operators_for`, `.valid_operator?` class methods

**TreeValidator** — recursive walker returning `{ valid: bool, errors: [{path:, message:}] }`:

- Validates combinators ('and'/'or'), max nesting depth (2), sub-group placement (root only)
- Validates field names (via FieldConfiguration), operator-field compatibility, array-value requirement for in/not_in
- Extracted helper methods to satisfy rubocop complexity metrics

**Executor** — includes `AdvancedSearch::Operators` + `AdvancedSearch::Filtering`:

- `visit_group` uses `acc.and(rel)` for AND, `acc.or(rel)` for OR
- `visit_condition` delegates to `add_condition(scope, node)` — ConditionNode is duck-type compatible
- `model_class` returns `Sample`; `normalize_condition_value` uppercases PUID for V1-compatible matching

### Task 2: Sample::V2::Query PORO

- `#results` returns `[Pagy::Offset, ActiveRecord::Relation]` tuple
- `#valid?` delegates to TreeValidator, populates `@errors`
- `apply_sort` handles standard columns and `metadata_*` JSONB columns via `Sample.metadata_sort`
- `#request` provides minimal `{ params: {} }` hash for Pagy::Method compatibility

## Test Coverage

| File                        | Tests  | Assertions |
| --------------------------- | ------ | ---------- |
| executor_test.rb            | 7      | 19         |
| field_configuration_test.rb | 9      | 13         |
| tree_validator_test.rb      | 11     | 27         |
| query_test.rb               | 10     | 18         |
| **Total**                   | **38** | **77**     |

Full suite (102 tests incl. V1): 0 failures, 0 errors.

## Commits

| Task | Hash      | Description                                                         |
| ---- | --------- | ------------------------------------------------------------------- |
| 1    | 9c2325ec0 | feat(01-01): Add V2 Executor, FieldConfiguration, and TreeValidator |
| 2    | d8313488f | feat(01-01): Add Sample::V2::Query PORO with pagination             |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrong fixture name in executor test**

- **Found during:** Task 1 GREEN phase
- **Issue:** Test referenced `samples(:sample_metadata_summary)` which doesn't exist
- **Fix:** Changed to `samples(:sample43)` which has `metadata: { insdc_accession: 'ERR86724108' }`
- **Files modified:** test/models/advanced_search/v2/executor_test.rb
- **Commit:** 9c2325ec0 (included in same commit)

**2. [Rule 1 - Bug] Pagy::Offset vs Pagy class mismatch**

- **Found during:** Task 2 GREEN phase
- **Issue:** Test asserted `assert_instance_of Pagy` but newer pagy returns `Pagy::Offset` subclass
- **Fix:** Changed to `assert_kind_of Pagy`
- **Files modified:** test/models/sample/v2/query_test.rb
- **Commit:** d8313488f (included in same commit)

**3. [Rule 1 - Bug] `Sample` is a class, not a module**

- **Found during:** Task 2 implementation
- **Issue:** `module Sample; module V2; class Query` fails because `Sample` is `class Sample < ApplicationRecord`
- **Fix:** Used `module Sample::V2` + `class Sample::V2::Query` with rubocop disable comments, matching existing `Sample::Query` pattern
- **Files modified:** app/models/sample/v2/query.rb

## Self-Check: PASSED
