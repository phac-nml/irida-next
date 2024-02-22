---
sidebar_position: 2
id: pipelines
title: Registering Pipelines
---

Pipelines must be registered in IRIDA Next to be able to launch workflows. They are registered when the server is started up and Future restarts of the server will only register new pipelines that are added to the configuration file, and schema files for a particular pipeline will update if newer versions are available in the repository.

## Pipeline repository

Currently only **Nextflow** pipelines are supported and they must have a Github repository. Each pipeline is required to have a `nextflow_schema.json` file at the top level of the repository, and a `schema_input.json` file under an `assets` directory within the repository.

## Setup

The configuration file to register pipelines is in `json` format and stored in the `config/pipelines/` directory with the name `pipelines.json`.

This `pipelines.json` file should be in the format below and must include the following:

- **URL** of the pipeline Github repository
- **name** of the pipeline
- **description** of the pipeline
- **versions** of the pipeline that should be available to launch

```json
[
  {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "versions": [
      {
        "name": "1.0.2"
      },
      {
        "name": "1.0.1"
      },
      {
        "name": "1.0.0"
      }
    ]
  },
  {
    ........
  }
]
```
