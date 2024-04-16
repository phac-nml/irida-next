---
sidebar_position: 1
id: ga4gh_wes_sapporo_setup
title: GA4GH WES Sapporo Setup
---

## Prerequisites

You will need to have [Docker Compose plugin](https://docs.docker.com/compose/install/linux/) installed for managing Sapporo

```bash
# Instructions for installing Docker Compose plugin on Ubuntu
sudo apt-get update
sudo apt-get install docker-compose-plugin
# Verify installation
docker compose version
# expected result
> Docker Compose version vN.N.N
```

You will need to add yourself to the docker group to be able to run docker commands

```bash
# create the docker group if it does not exist
sudo groupadd docker
# add yourself to the docker group
sudo usermod -aG docker $USER
# reboot, log out/log in, or run the following command
newgrp docker
# If you still have issues with running docker, you may need to change the permissions of the docker socket using the following command
sudo chmod 666 /var/run/docker.sock
```

## How to set up a Sapporo GA4GH WES instance for development

Note: This should only be used for development purposes, use a production WSGI server for production environments.

### Configure IRIDA Next

Check that your active storage service is set to `:local` in `config/environments/development.rb`. This is the default configuration.

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

Download and run the [PHAC-NML Sapporo](https://github.com/phac-nml/sapporo-service) fork in dev docker mode.

Note: If your docker group permissions are setup correctly you should not have to use `sudo` when running any of these commands.

```bash
# Go to wherever you store your git repos
cd ~/path/to/git/repos
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
