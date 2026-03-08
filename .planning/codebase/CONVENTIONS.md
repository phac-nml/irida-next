# Coding Conventions

**Analysis Date:** 2026-03-08

## Naming Patterns

**Files:**

- Ruby files: `snake_case.rb` (e.g., `transfer_service.rb`, `base_sample_service.rb`)
- ViewComponents: `{name}_component.rb` co-located with `{name}_component.html.erb`
- Namespaced files map to directories: `app/services/samples/transfer_service.rb` → `Samples::TransferService`
- JavaScript controllers: `{name}_controller.js` (Stimulus convention)
- Test files: mirror source path under `test/` with `_test.rb` suffix

**Classes:**

- Services: `PascalCase` under namespace module (e.g., `Samples::TransferService`)
- Controllers: `PascalCase` + `Controller` suffix (e.g., `GroupsController`)
- Policies: `PascalCase` + `Policy` suffix (e.g., `ProjectPolicy`, `SamplePolicy`)
- ViewComponents: `PascalCase` + `Component` suffix (e.g., `Activities::MemberActivityComponent`)
- Jobs: `PascalCase` + `Job` suffix
- GraphQL types: under `app/graphql/types/`, mutations under `app/graphql/mutations/`

**Methods:**

- `snake_case` throughout Ruby
- Private methods placed after `private` keyword at bottom of class
- Policy methods named with `?` suffix (e.g., `activity?`, `destroy_attachment?`, `transfer_sample?`)
- Service entry point always named `execute`

**Variables:**

- Instance variables for test fixtures: `@user`, `@group`, `@project` in `setup`
- `snake_case` for all locals and instance variables

## Code Style

**Formatting:**

- Prettier with `prettier-plugin-tailwindcss` for JS/HTML
- RuboCop with `rubocop-rails` and `rubocop-graphql` plugins
- Ruby target version: 3.3+

**Linting Rules (RuboCop):**

- `Metrics/MethodLength`: max 15 lines (comments excluded)
- `Metrics/AbcSize`: max 20
- `Style/Documentation`: required on all classes (except test files and components)
- `Lint/MissingSuper`: disabled for ViewComponents (`app/components/**/*.rb`)
- `GraphQL/ObjectDescription`: required on all non-base GraphQL objects

**JavaScript Rules (ESLint):**

- `prefer-const`: error (never use `let` when `const` suffices)
- `no-var`: error (no `var` declarations)
- `no-console`: warn (allow `console.error` and `console.warn`)
- `no-unused-vars`: warn (prefix unused vars/args with `_`)

## Frozen String Literals

All 471 Ruby source files begin with `# frozen_string_literal: true`. This is universal and non-negotiable. All new `.rb` files must include this as the first line.

## Import Organization (JavaScript)

**Order in Stimulus controllers:**

1. Framework imports (`@hotwired/stimulus`)
2. Utility/library imports
3. No barrel re-exports used in controllers

**Path Aliases:**

- None — uses importmap-rails with bare module specifiers

## Error Handling

**Rails controllers:**

- `rescue_from ActionPolicy::Unauthorized` in `ApplicationController` → renders `shared/error/not_authorized`
- `rescue_from ActiveRecord::RecordNotFound` → `not_found` helper rendering `shared/error/not_found`
- `rescue_from Pagy::RangeError` → redirects to first page
- Controllers respond to both `format.html` and `format.turbo_stream`

**Services:**

- Errors added to model via `@namespace.errors.add(:base, message)` and returned as empty array/nil
- Custom error classes nested inside service (e.g., `Samples::TransferService::TransferError < StandardError`)
- `rescue` at end of `execute` method catches `BaseSampleService::BaseError` and service-specific errors

**GraphQL:**

- Errors raised as `GraphQL::ExecutionError` for query-level failures
- Mutation responses include `errors { path message }` field for field-level errors

## Logging

**Framework:** Rails logger (`Rails.logger`)

**JavaScript:** `console.error`/`console.warn` only (no `console.log` per ESLint rule)

## Comments

**Ruby:**

- Service classes include class-level YARD-style documentation block with `@example`, `@param`, `@return`, `@raise`
- Method-level YARD docs on public service methods
- Inline comments explain non-obvious logic
- TODO comments use format: `# TODO: [description]` (feature-flag retirement TODOs are tracked this way)

**JavaScript:**

- File-level block comment with usage example (HTML snippet)
- JSDoc on public methods: `@param`, `@returns`, `@private`
- Private methods marked `@private` in JSDoc and use ES2022 private field syntax (`#methodName`)

## Function/Method Design

**Ruby:**

- `private` methods below explicit `private` keyword
- Services follow Command pattern: one public `execute` method orchestrates private helpers
- Authorization always first in `execute` via `authorize!`
- Max method length 15 lines enforced by RuboCop

**JavaScript (Stimulus):**

- Private helpers use ES2022 private class fields (`#tooltip`, `#notify()`)
- Lifecycle callbacks (`disconnect`, `connect`, `*TargetConnected`) handle setup/teardown
- Values API (`static values`) for configuration, Targets API for DOM refs

## Module Design

**Ruby:**

- Concerns in `app/models/concerns/`, `app/controllers/concerns/`
- Service namespacing mirrors feature area: `Samples::`, `Groups::`, `Members::`, etc.
- Policy inheritance chain: `ApplicationPolicy` → `NamespacePolicy` → `ProjectPolicy`
- ViewComponents under `app/components/`, namespaced by feature

**Exports (JavaScript):**

- Stimulus controllers: `export default class extends Controller`
- No named exports in controller files
- Utilities in `app/javascript/utilities/` can use named exports

## I18n

All user-facing strings use `I18n.t(...)`. Never hardcode English strings in views, controllers, or components. Locale keys in `config/locales/`.

---

_Convention analysis: 2026-03-08_
