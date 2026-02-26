# Pathogen Component Contract

## Purpose

This document defines the CSS and state contract every Pathogen component migration must follow during PR1-PR8.

## Naming Contract

- Prefix all public component selectors with `pathogen-`.
- Use BEM-like anatomy names:
  - Root: `.pathogen-<component>`
  - Child element: `.pathogen-<component>__<element>`
  - Modifier: `.pathogen-<component>--<modifier>`
- Shared helpers must use the `pathogen-u-*` namespace.
- Do not introduce unprefixed global utility classes.

## Layer Contract

Pathogen styles are split into explicit layers and imported in this order:

1. `pathogen.tokens`
2. `pathogen.utilities`
3. `pathogen.components`

Rules:

- Tokens define CSS custom properties and font faces.
- Utilities define low-level reusable helpers.
- Component files define only component-specific rules.

## State Contract

### JavaScript-controlled state

Use `data-state` attributes for JS-controlled UI state.

Examples:

- `data-state="open" | "closed"`
- `data-state="selected" | "today" | "disabled"`
- `data-state="initialized"`

Avoid toggling Tailwind utility classes with `classList`.

### Browser-native state

Use pseudo-classes for native states:

- `:hover`
- `:focus-visible`
- `:disabled`

### ARIA semantic state

Use ARIA selectors for semantic visibility/selection:

- `[aria-selected="true"]`
- `[aria-hidden="true"]`

## Visibility Contract

- For semantic panel visibility, prefer `aria-hidden` + CSS selectors.
- For simple show/hide behavior (errors, transient messages), use the HTML `hidden` attribute.
- Do not introduce a generic `pathogen-u-hidden` utility.

## Token Contract

- Primitive color tokens use `oklch`.
- Component rules consume semantic tokens, not hard-coded color literals where avoidable.
- Brand override surface is limited to:
  - `--pathogen-color-brand-500`
  - `--pathogen-color-brand-600`
  - `--pathogen-color-brand-700`

## Compatibility Contract

For one release cycle during migration:

- Existing public component APIs must remain stable unless explicitly documented.
- Compatibility aliases may be retained where required to avoid host regressions.
- New work must not add fresh Tailwind utility strings inside Pathogen component Ruby/ERB/JS.

## Per-PR Acceptance Checks

Every Pathogen migration PR should include:

1. Component CSS migrated to semantic Pathogen classes.
2. JS state toggles migrated to `data-state` or semantic attributes.
3. Tests updated to assert semantic behavior/contracts rather than Tailwind classes.
4. Light and dark mode verification evidence.
