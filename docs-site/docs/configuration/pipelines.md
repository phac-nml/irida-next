---
sidebar_position: 3
id: pipelines
title: Registering Pipelines
---

Pipelines are registered when the IRIDA Next server is started up. Future restarts of the server will only register new pipelines that are added to the configuration file, and schema files for a particular pipeline will update if newer versions are available in the repository.

## Pipeline repository

Currently, only **Nextflow** pipelines are supported and they must have a GitHub repository. Each pipeline is required to have a `nextflow_schema.json` file at the top level of the repository, and a `schema_input.json` file under an `assets` directory within the repository.

## Setup

### Configuration

The configuration file to register pipelines is in `json` format and stored in the `config/pipelines/` directory with the name `pipelines.json`.

This `pipelines.json` file should be in the format below and can include the following:

- **URL** _(Required)_ of the pipeline GitHub repository
- **name** _(Required)_ of the pipeline
- **description** _(Required)_ of the pipeline
- **versions** _(Required)_ of the pipeline that should be available to launch.
  - `name`: _(Required)_ refers to the `-r` flag used by nextflow.
  - `automatable`: _(Optional)_ `true` or `false` to specify if the pipeline can be automated.
  - `executable`: _(Optional)_ `true` or `false` to specify if the pipeline is able to be executed. When set to `false`, the pipeline will not be listed to the user.
- **overrides** _(Optional)_ for the pipeline
- **samplesheet_overrides** _(Optional)_ for the pipeline

#### Example

```json
{
  "phac-nml/iridanextexample": {
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
  "some-other/pipeline": {
    ...
  }
}
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
{
  "phac-nml/iridanextexample": {
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
    ...
  }
}
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

### Samplesheet Overrides

The Samplesheet Overrides section can be used to change anything within the original pipeline samplesheet. Anything within the `"samplesheet_overrides": {<json data>}` will overwrite the original samplesheet with `<json data>` starting at the highest level.

In the below example, we will override the default selected metadata fields. Note that only the overridden fields need to be provided, as everything else provided by the default samplesheet stays the same.

#### Example schema

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "My Example Schema",
  "description": "Example Schema: for demonstrating samplesheet overrides",
  "items": {
        "type": "object",
        "properties": {
            "sample": {
                "type": "string",
                "pattern": "^\\S+$",
                "meta": ["irida_id"],
                "unique": true,
                "errorMessage": "Sample name must be provided and cannot contain spaces."
            },
            "sample_name": {
                "type": "string",
                "meta": ["id"],
                "errorMessage": "Sample name is optional, if provided will replace sample for filenames and outputs"
            },
            "mlst_alleles": {
                "type": "string",
                "format": "file-path",
                "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
                "errorMessage": "MLST JSON file from locidex report, cannot contain spaces and must have the extension: '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json', or 'mlst.subtyping.json.gz'"
            },
            "fastmatch_category": {
                "type": "string",
                "errorMessage": "Has to be either query or reference",
                "description": "Identify whether a sample is query or reference",
                "fa_icon": "far fa-sticky-note",
                "enum": ["query", "reference"]
            },
            "metadata_1": {
                "type": "string",
                "meta": ["metadata_1"],
                "errorMessage": "Metadata associated with the sample (metadata_1).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$"
            },
            "metadata_2": {
                "type": "string",
                "meta": ["metadata_2"],
                "errorMessage": "Metadata associated with the sample (metadata_2).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$"
            },
           .........
        },
        "required": ["sample", "mlst_alleles"]
    }
}
```

#### Example pipeline entry level samplesheet override

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "samplesheet_overrides": {
      "items": {
        "properties": {
            "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
            },
            "metadata_2": {
                "x-irida-next-selected": "prediceted_primary_identification_name"
            },
            .........
        },
        "required": ["sample", "mlst_alleles"]
      }
    },
    "versions": [...]
  },
  "some_other_pipeline": {
    ........
  }
}
```

#### Effective Result

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "My Example Schema",
  "description": "Example Schema: for demonstrating samplesheet overrides",
  "type": "object",
   "items": {
      "type": "object",
      "properties": {
          "sample": {
              "type": "string",
              "pattern": "^\\S+$",
              "meta": ["irida_id"],
              "unique": true,
              "errorMessage": "Sample name must be provided and cannot contain spaces."
          },
          "sample_name": {
              "type": "string",
              "meta": ["id"],
              "errorMessage": "Sample name is optional, if provided will replace sample for filenames and outputs"
          },
          "mlst_alleles": {
              "type": "string",
              "format": "file-path",
              "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
              "errorMessage": "MLST JSON file from locidex report, cannot contain spaces and must have the extension: '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json', or 'mlst.subtyping.json.gz'"
          },
          "fastmatch_category": {
              "type": "string",
              "errorMessage": "Has to be either query or reference",
              "description": "Identify whether a sample is query or reference",
              "fa_icon": "far fa-sticky-note",
              "enum": ["query", "reference"]
          },
          "metadata_1": {
              "type": "string",
              "meta": ["metadata_1"],
              "errorMessage": "Metadata associated with the sample (metadata_1).",
              "default": "",
              "pattern": "^[^\\n\\t\"]+$",
              "x-irida-next-selected": "new_isolates_date"
          },
          "metadata_2": {
              "type": "string",
              "meta": ["metadata_2"],
              "errorMessage": "Metadata associated with the sample (metadata_2).",
              "default": "",
              "pattern": "^[^\\n\\t\"]+$",
              "x-irida-next-selected": "prediceted_primary_identification_name"
          },
         ........
      },
      "required": ["sample", "mlst_alleles"]
    }
}
```

#### Example pipeline version level samplesheet override

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "versions": [
      {
        "name": "1.0.3",
        "samplesheet_overrides": {
          "items": {
            "properties": {
              "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
              },
              "metadata_2": {
                "x-irida-next-selected": "prediceted_primary_identification_name"
              },
            .........
            },
            "required": ["sample", "mlst_alleles"]
          }
        }
      },
      ......
    ],
    ........
  },
  "some other pipeline": {
    .........
  }
}
```

#### Effective Result

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "My Example Schema",
  "description": "Example Schema: for demonstrating samplesheet overrides",
  "type": "object",
  "versions": [
    {
      "name": "1.0.3",
      "items": {
        "type": "object",
        "properties": {
            "sample": {
                "type": "string",
                "pattern": "^\\S+$",
                "meta": ["irida_id"],
                "unique": true,
                "errorMessage": "Sample name must be provided and cannot contain spaces."
            },
            "sample_name": {
                "type": "string",
                "meta": ["id"],
                "errorMessage": "Sample name is optional, if provided will replace sample for filenames and outputs"
            },
            "mlst_alleles": {
                "type": "string",
                "format": "file-path",
                "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
                "errorMessage": "MLST JSON file from locidex report, cannot contain spaces and must have the extension: '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json', or 'mlst.subtyping.json.gz'"
            },
            "fastmatch_category": {
                "type": "string",
                "errorMessage": "Has to be either query or reference",
                "description": "Identify whether a sample is query or reference",
                "fa_icon": "far fa-sticky-note",
                "enum": ["query", "reference"]
            },
            "metadata_1": {
                "type": "string",
                "meta": ["metadata_1"],
                "errorMessage": "Metadata associated with the sample (metadata_1).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$",
                "x-irida-next-selected": "new_isolates_date"
            },
            "metadata_2": {
                "type": "string",
                "meta": ["metadata_2"],
                "errorMessage": "Metadata associated with the sample (metadata_2).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$",
                "x-irida-next-selected": "prediceted_primary_identification_name"
            },
          ........
        },
        "required": ["sample", "mlst_alleles"]
      },
      ..........
    }
  ]
}
```
