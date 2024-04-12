---
sidebar_position: 1
id: ga4gh_wes_sapporo_setup
title: GA4GH WES Sapporo Setup
---

## Prerequisites

You will need to have [Docker](https://docs.docker.com/get-docker/) installed for managing Sapporo

## How to set up a Sapporo GA4GH WES instance for development

Note: This should only be used for development purposes, use a production WSGI server for production environments.

### Configure IRIDA Next

Set active storage service to `:local` in `config/environments/development.rb`

```ruby
config.active_storage.service = :local
```

Configure environment developer credentials

```bash
EDITOR="vim --nofork" bin/rails credentials:edit --environment development
```

```yml
ga4gh_wes:
  server_url_endpoint: 'http://localhost:1122/'
```

### Setup Sapporo (WES implementation)

Download and run the [PHAC-NML Sapporo](https://github.com/phac-nml/sapporo-service) fork in dev docker mode

```bash
# Clone and checkout the irida-next branch
git clone git@github.com:phac-nml/sapporo-service.git
cd sapporo-service
# This branch has a custom docker compose script for irida next
git checkout irida-next
# Replace /PATH/TO/IRIDA/NEXT/REPO with your irida next repo path.
# This allows the docker container read/write access to the repo
# This is needed for it to read the input files, and write the output files back to the blob directories
IRIDA_NEXT_PATH=/PATH/TO/IRIDA/NEXT/REPO docker compose -f compose.irida-next.yml up -d --build
IRIDA_NEXT_PATH=/PATH/TO/IRIDA/NEXT/REPO docker compose -f compose.irida-next.yml exec app bash
# Within docker container, start sapporo
sapporo
```

In a new terminal confirm sapporo is running

```bash
# This should output all the service information for this ga4gh wes instance
curl -X GET http://localhost:1122/service-info
```

You should now be able to start IRIDA Next and run workflows with full GA4GH WES integration
