---
sidebar_position: 3
id: useful_commands
title: Useful Commands for Development
---

### Drop, rebuild and seed db

``` bash
bin/rails db:drop db:create db:migrate db:seed
```

### Create new credentials

``` bash
rm config/credentials.yml.enc
EDITOR="vim --nofork" bin/rails credentials:edit
```

### Additional process to have UI changes updated as they are changed

When running the server with `bin/rails s` instead of `bin/dev`, like when attaching the debugger in VSCode, the tailwind process can be run separately.

``` bash
bin/rails tailwindcss:watch
```

### Build graphql schema

``` bash
bin/rails graphql:dump_schema
```
