---
applyTo: "**/*.js,**/esbuild.config.mjs"
---
# esbuild & JavaScript Asset Guidelines

## Core Concepts
- This project bundles JavaScript with **esbuild** (`esbuild.config.mjs`), not Rails Import Maps — there is no `config/importmap.rb`
- `pnpm` manages JS dependencies; `pnpm-lock.yaml` is the source of truth
- Works with Turbo and Stimulus in Rails applications via standard ESM imports

## Configuration Best Practices
- Define bundle entry points in `esbuild.config.mjs`'s `entryPoints` map (e.g. `application`, `active_admin`, worker scripts)
- Output is written to `app/assets/builds` and served via Propshaft
- Declare new npm dependencies in `package.json` and install with `devenv shell -- pnpm install`
- Host-aliased packages (e.g. `@hotwired/stimulus`) are deduped against the `pathogen_view_components` gem's bundled JS via the `alias` map — do not remove existing aliases without understanding the single-instance requirement they enforce

## Directory Structure
- Organize JavaScript files in `app/javascript` directory
- Group related functionality in subdirectories (e.g., `controllers`, `utilities`, `workers`)
- Keep Stimulus controllers in `app/javascript/controllers`
- Use index files to export components from directories
- Follow module naming conventions consistently

## Module Usage Patterns
- Import modules using standard ESM syntax: `import { Controller } from "@hotwired/stimulus"`
- Avoid global namespace pollution by keeping imports scoped
- Use named exports for better code discoverability
- Lazy load modules for performance when appropriate (e.g. dynamic `import()` for worker scripts)

## Build & Watch Commands
- Build once: `devenv shell -- pnpm run build:js` (or `devenv shell -- pnpm build` for JS+CSS)
- Watch mode during development: `devenv shell -- pnpm run dev:js`
- Production builds minify and omit sourcemaps automatically (`NODE_ENV=production` or `RAILS_ENV=production`)

## Testing
- Write unit tests for Stimulus controllers and JS utilities with Vitest (`vitest.config.js`)
- Run `devenv shell -- pnpm test:js` for fast feedback, `devenv shell -- pnpm test:js:coverage` before opening a PR
- Follow the conventions in `docs/testing/javascript.md` for controller lifecycle, mocking, and coverage expectations

## Security Best Practices
- Pin to specific versions in `package.json` to prevent supply chain attacks
- Regularly update dependencies for security patches
- Use Content Security Policy headers (with nonces) to restrict inline script sources
- Validate externally-sourced scripts/content before including them in the bundle
