---
sidebar_position: 1
id: getting-started
title: Getting Started
---

In IRIDA Next, analysis of samples is performed using workflow execution pipelines.

## Workflow Execution Types

There are two types of workflow executions in IRIDA Next:

| Workflow Execution Type | Description                                                                                                                     |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| User                    | Allows users to select any number of samples belonging to either a group or project and perform an analysis on them.            |
| Automated               | Automated workflow executions belong to projects and once set-up, an analysis is performed on all newly uploaded paired-end files within that project |

User workflow executions are personal and are only accessible to the user that created it, while automated workflow executions are accessible to all project members who have at least the Analyst role.

## Requirements

You will require the following to perform workflow executions:
  - User workflow execution
    - Project that has at least one associated sample, and paired-end files uploaded to the sample.
    - At least the Analyst role for the project containing samples for workflow execution.
  - Automated workflow execution
    - A project and at least the Maintainer role for this project.

## Workflow Execution States

While a workflow execution is running, it will go through numerous states to give you feedback on its progress.

  States for a successful workflow execution (in order):

  | State      | Description                                                                                                                 |
  | :--------- | :-------------------------------------------------------------------------------------------------------------------------- |
  | New        | This is the initial state acknowledging the workflow execution has successfully created and prepares its files for analysis |
  | Prepared   | Files were successfully prepared and is being submitted to the selected pipeline                                            |
  | Submitted  | The workflow execution was submitted to the selected pipeline                                                               |
  | Running    | The workflow execution is being executed by the selected pipeline                                                           |
  | Completing | The analysis was successful and IRIDA Next is finalizing the workflow execution for the user                                |
  | Completed  | The workflow execution is complete and ready for the user                                                                   |

  Error states:

  | State     | Description                                                                                |
  | :-------- | :----------------------------------------------------------------------------------------- |
  | Error     | An error occurred during analysis and the run was aborted                                  |
  | Canceling | The workflow execution was canceled and IRIDA Next is in the process of canceling the run  |
  | Canceled  | The workflow execution successfully canceled                                               |

The current state of any workflow execution is shown on the workflow execution [listing page](../analysis/working-with-workflow-executions).

## Workflow Execution Deletions

When deleting a workflow execution, there are a couple points to keep in mind:
  - Deleted errored and canceled runs have no additional considerations
  - Deleting completed runs does not delete the associated results that have been propogated to the samples
