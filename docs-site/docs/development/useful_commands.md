---
sidebar_position: 3
id: useful_commands
title: Useful Commands for Development
---

### Local Pathogen View Components (sibling checkout)

To work against a local `../pathogen-view-components` checkout instead of the Gemfile tag:

```bash
export USE_LOCAL_PATHOGEN=1
bundle install
```

Or point Bundler at any checkout:

```bash
export PATHOGEN_VIEW_COMPONENTS_PATH=/absolute/path/to/pathogen-view-components
bundle install
```

Before committing, unset these environment variables and run `bundle install` again so `Gemfile.lock` stays on the published tag. Do not commit lockfile changes from local-path mode.

Open both repositories in Cursor with `irida-pathogen.code-workspace` (multi-root) so Lookbook docs and gem code sit alongside the host app.

### Drop, rebuild, and seed the database

```bash
bin/rails db:drop db:create db:migrate db:seed
```

### Create new credentials

```bash
rm config/credentials.yml.enc
EDITOR="vim --nofork" bin/rails credentials:edit
```

### Rebuild CSS while the Rails server is running

When you run the server with `bin/rails s` instead of `bin/dev` (for example, when attaching the VS Code debugger), start the CSS build process separately:

```bash
pnpm run dev:css
```

### Build the GraphQL schema

```bash
bin/rails graphql:dump_schema
```

### Build and serve the docs

```bash
cd docs-site
pnpm update
pnpm build
npm run serve
```

### Output logs during Rake tasks

Prepend Rake tasks with `info`, `debug`, or `verbose` to set the logging level:

```bash
# Example
rake debug db:seed
```

### Format translation files

```bash
i18n-tasks normalize
```
