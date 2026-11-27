# IRIDA Next — Rails 8 Application

This is a Rails 8.1 application built with modern practices including Turbo, Stimulus, GoodJob, and ViewComponent. Follow these guidelines for all code generation.

## General Coding Guidelines

- Use semantic and clean HTML in ERB templates
- Follow Ruby style conventions (2-space indentation, snake_case methods)
- Use Turbo for page transitions and dynamic updates
- Implement Stimulus controllers for interactive elements
- Utilize Tailwind CSS v4 for styling with component-based design
- Keep controllers thin, move logic to service objects when appropriate
- Use esbuild for JavaScript bundling (this project does not use Rails Import Maps)
- Use GoodJob for background job processing
- Use `action_policy` (not Pundit/CanCanCan) for authorization
- Never hardcode user-facing strings; add i18n keys to `config/locales/`

## Technology Stack

- Rails 8.1, Ruby 3.4+
- Turbo & Stimulus (Hotwire)
- GoodJob for background jobs
- PostgreSQL 18 (`hstore`, `pg_trgm`)
- Tailwind CSS v4
- esbuild for JavaScript bundling
- ViewComponent with `Pathogen::*` components (prefer over legacy `Viral::*`)
- GraphQL via `graphql` + `action_policy-graphql`
- Devise + OmniAuth (Entra ID, SAML) for authentication
- `paranoia` for soft deletion, `logidze` for audit history
- Flipper feature flags (`config/features.yml`)

## Project Architecture

This application follows a standard Rails structure with some specific organization:

- Controllers are minimal and focused on presentation
- Service objects handle complex business logic
- Background jobs process asynchronous tasks
- Policies in `app/policies/` (ActionPolicy) handle authorization
- Use Turbo and Stimulus for interactive components
- Use esbuild for bundling JavaScript, organized under `app/javascript`
- Follow Rails conventions for file structure and naming

## Specialized Instruction Files

This application uses specialized instruction files to define best practices for specific areas:

- Rails 8: See `.github/instructions/rails8.instructions.md` for Rails 8 conventions
- Turbo/Stimulus: See `.github/instructions/turbo-stimulus.instructions.md` for Hotwire patterns
- TailwindCSS: See `.github/instructions/tailwind.instructions.md` for styling guidelines
- esbuild/JavaScript assets: See `.github/instructions/esbuild.instructions.md` for JS bundling conventions
- View helpers: See `.github/instructions/view-helpers.instructions.md` for Action View helper conventions

See also `AGENTS.md` at the repository root for environment setup (`devenv.sh`), essential commands, and repository boundaries.
