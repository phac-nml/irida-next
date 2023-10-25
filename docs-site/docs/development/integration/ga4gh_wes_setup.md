---
sidebar_position: 1
id: ga4gh_wes_setup
title: GA4GH WES Setup
---

[This guide loosely follows the starter kit guide here](https://starterkit.ga4gh.org/docs/starter-kit-apis/wes/wes_run_request)

get docker image

[Image versions found here](https://hub.docker.com/r/ga4gh/ga4gh-starter-kit-wes/tags)

```bash
docker pull ga4gh/ga4gh-starter-kit-wes:0.3.2-nextflow
```

make a config dir somewhere

```bash
mkdir ~/wesconfig
```

make config file

```bash
cd wesconfig
touch config.yml
```

add the following to the config file

```yml
wes:
  serverProps:
    publicApiPort: 7500
    adminApiPort: 7501
  serviceInfo:
    id: org.ga4gh.demo.wes.test
    name: WES API Test Demo
  databaseProps:
    url: jdbc:sqlite:/home/user/db/ga4gh-starter-kit.dev.db
```

run wes

```bash
docker run \
  --name sk-wes-test \
  -p 7500:7500 \
  -p 7501:7501 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/shared/wes:/tmp/shared/wes \
  -v ~/wesconfig:/config \
  --workdir "/tmp/shared/wes" \
  ga4gh/ga4gh-starter-kit-wes:0.3.2-nextflow \
  -c /config/config.yml
```

make a GET request to `http://localhost:7500/ga4gh/wes/v1/service-info`

I like using [POSTMAN](https://www.postman.com/downloads/) for api debugging

expected response

```json
{
    "id": "org.ga4gh.demo.wes.test",
    "name": "WES API Test Demo",
    "description": "An open source, community-driven implementation of the GA4GH Workflow Execution Service (WES)API specification.",
    "contactUrl": "mailto:info@ga4gh.org",
    "documentationUrl": "https://github.com/ga4gh/ga4gh-starter-kit-wes",
    "createdAt": "2020-01-15T12:00:00Z",
    "updatedAt": "2020-01-15T12:00:00Z",
    "environment": "test",
    "version": "0.3.2",
    "type": {
        "group": "org.ga4gh",
        "artifact": "wes",
        "version": "1.0.1"
    },
    "organization": {
        "name": "Global Alliance for Genomics and Health",
        "url": "https://ga4gh.org"
    },
    "workflow_type_versions": {
        "WDL": [
            "1.0"
        ],
        "NEXTFLOW": [
            "21.04.0"
        ]
    },
    "workflow_engine_versions": {
        "NATIVE": "1.0.0"
    }
}
```

[more commands can be found here](https://starterkit.ga4gh.org/docs/starter-kit-apis/wes/wes_run_request)

## Authentication

If you are using authentication, you can set the following
Use `bin/rails credentials:edit`` to set the GA4GH WES secrets (as ga4gh_wes:oauth_token)
