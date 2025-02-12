---
sidebar_position: 2
id: graphql_workflow_submission
title: GraphQL Workflow Submission Tutorial
---

### Please Note:

This is an advanced feature. Please familiarize yourself with the [GraphQL API Documentation](./graphql) before continuing with this tutorial.

## Overview

Submitting a workflow execution via the GraphQL API is done in multiple steps. It is expected that this will be done programmatically and not manually. Many id's will be fetched and used in the submission process so simply copying and pasting the values will likely result in user error.

Steps:

1. Query for pipelines
2. Query specific pipeline information
3. Query Project information
4. Query Sample and File data from Project
5. Submit a Workflow Execution using the information queried in the previous steps

Please note: All values fetched by executing these queries are unique to your database. Copying and Pasting the commands without replacing the values with your own id's will not work.

### 1. Query for pipelines

Query the list of pipelines to find the one you want to use.

```graphql
query getPipelines {
    pipelines(workflowType: "available"){
        name
        version
  }
}
```

Result

```json
{
  "data": {
    "pipelines": [
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.3"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.2"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.1"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.0"
      }
    ]
  }
}
```

The `name` and `version` fields will be used in the next step. In this example version `1.0.1`.

### 2. Query for Pipeline Information

We are able to get all the information about a pipeline with this query.

```graphql
query getPipelineInfo {
    pipeline(workflowName:"phac-nml/iridanextexample",workflowVersion:"1.0.3"){
    automatable
    description
    executable
    metadata
    name
    version
    workflowParams
  }
}
```

Result:

```json
{
  "data": {
    "pipeline": {
      "automatable": false,
      "description": "IRIDA Next Example Pipeline",
      "executable": true,
      "metadata": {
        "workflow_name": "phac-nml/iridanextexample",
        "workflow_version": {
          "name": "1.0.3"
        }
      },
      "name": "phac-nml/iridanextexample",
      "version": "1.0.3",
      "workflowParams": {
        "input_output_options": {
          "title": "Input/output options",
          "description": "Define where the pipeline should find input data and save output data.",
          "properties": {
            "input": {
              "type": "string",
              "format": "file-path",
              "exists": true,
              "mimetype": "text/csv",
              "pattern": "^\\S+\\.csv$",
              "schema": {
                "$schema": "http://json-schema.org/draft-07/schema",
                "$id": "https://raw.githubusercontent.com/phac-nml/iridanextexample/main/assets/schema_input.json",
                "title": "phac-nml/iridanextexample pipeline - params.input schema",
                "description": "Schema for the file provided with params.input",
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "sample": {
                      "type": "string",
                      "pattern": "^\\S+$",
                      "meta": [
                        "id"
                      ],
                      "unique": true,
                      "errorMessage": "Sample name must be provided and cannot contain spaces"
                    },
                    "fastq_1": {
                      "type": "string",
                      "pattern": "^\\S+\\.f(ast)?q(\\.gz)?$",
                      "errorMessage": "FastQ file for reads 1 must be provided, cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'"
                    },
                    "fastq_2": {
                      "errorMessage": "FastQ file for reads 2 cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'",
                      "anyOf": [
                        {
                          "type": "string",
                          "pattern": "^\\S+\\.f(ast)?q(\\.gz)?$"
                        },
                        {
                          "type": "string",
                          "maxLength": 0
                        }
                      ]
                    }
                  },
                  "required": [
                    "sample",
                    "fastq_1"
                  ]
                }
              },
              "description": "Path to comma-separated file containing information about the samples in the experiment.",
              "help_text": "You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row.",
              "fa_icon": "fas fa-file-csv",
              "required": false
            },
            "project_name": {
              "type": "string",
              "default": "assembly",
              "pattern": "^\\S+$",
              "description": "The name of the project.",
              "fa_icon": "fas fa-tag",
              "required": false
            },
            "assembler": {
              "type": "string",
              "default": "stub",
              "fa_icon": "fas fa-desktop",
              "description": "The sequence assembler to use for sequence assembly.",
              "enum": [
                "default",
                "stub",
                "experimental"
              ],
              "required": false
            },
            "random_seed": {
              "type": "integer",
              "default": 1,
              "fa_icon": "fas fa-dice-six",
              "description": "The random seed to use for sequence assembly.",
              "minimum": 1,
              "required": false
            }
          }
        }
      }
    }
  }
}
```

The output informs us of the structure of the fields we will provide to run the pipeline.

Specifically, We will be using the following fields from the result

* `workflowName`
* `workflowVersion`
* `workflowParams`
  * `assembler`
  * `random_seed`
  * `project_name`

The output also informs us of the structure for the `samplesWorkflowExecutionAttributes` (`sample_id`) and `samplesheet_params` (`sample`, `fastq_1`, `fastq_2`) in our final submission query.

### 3. Query Project information

Query to find the Project containing the samples you want to use in the pipeline. In this example we are simply getting the first project.

```graphql
query getProjects {
  projects(first: 1){
    nodes{
      fullName
      id
      fullPath
    }
  }
}
```

Result

```json
{
  "data": {
    "projects": {
      "nodes": [
        {
          "fullName": "Borrelia / Borrelia burgdorferi / Outbreak 2024",
          "id": "gid://irida/Project/2bd03791-2213-444d-8df3-fdda40fc262a",
          "fullPath": "borrelia/borrelia-burgdorferi/outbreak-2024"
        }
      ]
    }
  }
}
```

We will be using the `fullPath` field in the next step, and `id` in the final step

### 4. Query Sample and File data from Project

Using the `fullPath` from the previous step, we will query for the sample and file information we will use in the pipeline.

Step 2 informed us that we the sample `id`, the sample `puid`, and file (attachment) `id`'s

In this example we are only going to use 1 sample.

```graphql
query getProjectInfo{
  project(fullPath: "borrelia/borrelia-burgdorferi/outbreak-2024") {
    samples(first:1){
      nodes{
        id
        puid
        attachments{
          nodes{
            filename
            id
          }
        }
      }
    }
  }
}
```

Result

```json
{
  "data": {
    "project": {
      "samples": {
        "nodes": [
          {
            "id": "gid://irida/Sample/c9f3806d-4bf1-4462-bc46-7b547338cc11",
            "puid": "INXT_SAM_AZCMYRDHEJ",
            "attachments": {
              "nodes": [
                {
                  "filename": "reference.fasta",
                  "id": "gid://irida/Attachment/b6ab6077-b3bf-4d5a-ba0c-dc97de7741df"
                },
                {
                  "filename": "08-5578-small_S1_L001_R2_001.fastq.gz",
                  "id": "gid://irida/Attachment/cad0ae33-0c82-4960-8580-92358686609f"
                },
                {
                  "filename": "08-5578-small_S1_L001_R1_001.fastq.gz",
                  "id": "gid://irida/Attachment/f2fad21f-f68f-4871-990f-b47880bed390"
                }
              ]
            }
          }
        ]
      }
    }
  }
}
```

In our example, we are interested in the forward and reverse reads, filenames `08-55...R1...fastq.gz` and `08-55...R2...fastq.gz`. Take care to note which file id is forward and reverse as the next step will accept them as `fastq_1` and `fastq_2`.

### 5. Submit a Workflow Execution using the information queried in the previous steps

Using all the information gathered in the previous steps, we can now submit our Workflow Execution.

Since this is a Mutation, we also include the `workflowExecution` and `error` blocks to see the if our submission succeeded.

```graphql
mutation submitWorkflowExecution {
  submitWorkflowExecution (input:{
    name:"My Workflow Submission from GraphQL"
    projectId: "gid://irida/Project/2bd03791-2213-444d-8df3-fdda40fc262a"
    updateSamples: false
    emailNotification: false
    workflowName: "phac-nml/iridanextexample"
    workflowVersion:"1.0.3"
    workflowParams: {
      assembler: "stub",
      random_seed: 1,
      project_name: "assembly"
    }
    samplesWorkflowExecutionsAttributes:[
      {
        sample_id:"gid://irida/Sample/c9f3806d-4bf1-4462-bc46-7b547338cc11"
        samplesheet_params:{
          sample: "INXT_SAM_AZCMYRDHEJ",
          fastq_1:"gid://irida/Attachment/f2fad21f-f68f-4871-990f-b47880bed390",
          fastq_2:"gid://irida/Attachment/cad0ae33-0c82-4960-8580-92358686609f"
        }
      }
    ]
  }){
    workflowExecution{
      name
      state
      id
    }
    errors{
      message
      path
    }
  }
}
```

Result

```json
{
  "data": {
    "submitWorkflowExecution": {
      "workflowExecution": {
        "name": "My Workflow Submission from GraphQL",
        "state": "initial",
        "id": "gid://irida/WorkflowExecution/468dcdb5-cf94-4deb-b0b6-67033f156af4"
      },
      "errors": []
    }
  }
}
```

If we now look at the Workflow Executions page in IRIDA Next, we should see our submitted pipeline.
