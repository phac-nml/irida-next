---
sidebar_position: 3
id: useful_commands
title: Useful Commands for Development
---

### Drop, rebuild and seed db

``` bash
rake db:drop db:create db:migrate db:seed
```

### Create new credentials

``` bash
rm config/credentials.yml.enc
EDITOR="vim --nofork" bin/rails credentials:edit
```

### Run this additional process to have UI changes updated as they are changed

``` bash
bin/rails tailwindcss:watch
```

### Build graphql schema

``` bash
bin/rails graphql:dump_schema
```
