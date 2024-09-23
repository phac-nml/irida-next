---
sidebar_position: 3
id: pipelines
title: Registering Pipelines
---

Pipelines must be registered in IRIDA Next to be able to launch workflows. They are registered when the server is started up and Future restarts of the server will only register new pipelines that are added to the configuration file, and schema files for a particular pipeline will update if newer versions are available in the repository.

## Pipeline repository

Currently only **Nextflow** pipelines are supported and they must have a Github repository. Each pipeline is required to have a `nextflow_schema.json` file at the top level of the repository, and a `schema_input.json` file under an `assets` directory within the repository.

## Setup

### Configuration

The configuration file to register pipelines is in `json` format and stored in the `config/pipelines/` directory with the name `pipelines.json`.

This `pipelines.json` file should be in the format below and can include the following:

- **URL** *(Required)* of the pipeline Github repository
- **name** *(Required)* of the pipeline
- **description** *(Required)* of the pipeline
- **versions** *(Required)* of the pipeline that should be available to launch.
  - `name`: *(Required)* refers to the `-r` flag used by nextflow.
  - `automatable`: *(Optional)* `true` or `false` to specify if the pipeline can be automated.
  - `executable`: *(Optional)* `true` or `false` to specify if the pipeline is able to be executed. When set to `false`, the pipeline will not be listed to the user.
- **overrides** *(Optional)* for the pipeline

#### Example

```json
[
  {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "overrides": {
      # SEE OVERRIDE SECTION BELOW
    },
    "versions": [
      {
        "name": "1.0.2",
        "automatable": true,
        "executable": true
      },
      {
        "name": "1.0.1",
        "automatable": true,
        "executable": false
      },
      {
        "name": "1.0.0",
        "automatable": false,
        "executable": true
      }
    ]
  },
  {
    ........
  }
]
```

### Schema Overrides

The Overrides section can be used to change anything within the original nextflow pipeline schema. Anything within the `"overrides": {<json data>}` will overwrite the original schema with `<json data>` starting at the highest level.

In the below example, we will override the database connection options so we can connect the pipeline to our custom database path. Note that only the overridden fields need to be provided, as everything else provided by the schema stays the same.

#### Example schema

```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "My Example Schema",
    "description": "Example Schema: for demonstrating overrides",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Input/Output Options",
            "type": "object",
            "description": "Define which data to use with the pipeline.",
            "required": ["input", "outdir"],
            "properties": {
                "input": {
                    ...
                },
                "outdir": {
                    ...
                },
                "database": {
                  "type": "string",
                  "description": "Kraken DB",
                  "enum": [
                    [
                      "default_db",
                      "PATH_TO_DB"
                    ],
                    [
                      "organization db",
                      "PATH_TO_ORG_DB"
                    ]
                  ]
                }
            }
        },
        "more options": {
          ...
        }
    },
    "more options": {
      ...
    }
}
```

#### Example override

```json
[
  {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "overrides": {
      "definitions": {
        "input_output_options": {
          "properties": {
            "database": {
              "enum": [
                [
                  "custom_db",
                  "PATH_TO_CUSTOM_DB"
                ],
                [
                  "custom_db_2",
                  "PATH_TO_CUSTOM_DB_2"
                ]
              ]
            }
          }
        }
      }
    },
    "versions": [...]
  },
  {
    ........
  }
]
```

#### Effective Result


```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "My Example Schema",
    "description": "Example Schema: for demonstrating overrides",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Input/Output Options",
            "type": "object",
            "description": "Define which data to use with the pipeline.",
            "required": ["input", "outdir"],
            "properties": {
                "input": {
                    ...
                },
                "outdir": {
                    ...
                },
                "database": {
                  "type": "string",
                  "description": "Kraken DB",
                  "enum": [
                    [
                      "custom_db",
                      "PATH_TO_CUSTOM_DB"
                    ],
                    [
                      "custom_db_2",
                      "PATH_TO_CUSTOM_DB_2"
                    ]
                  ]
                }
            }
        },
        "more options": {
          ...
        }
    },
    "more options": {
      ...
    }
}
```
