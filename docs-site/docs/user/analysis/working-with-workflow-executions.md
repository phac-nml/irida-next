---
sidebar_position: 3
id: working-with-workflow-executions
title: Working with Workflow Executions
---

## Workflow Execution States

While a workflow execution is executing, it will go through numerous states to give you feedback on its progress.

The states and a description of each state is the following:

  Successful workflow execution run states:

    | State         | Description                                                                                                   |
    | :------------ | :------------------------------------------------------------------------------------------------------------ |
    | 1. New        | This is the initial state acknowledging the workflow execution is newly created                               |
    | 2. Prepared   | IRIDA Next prepares the files to be submitted for analysis                                                    |
    | 3. Submitted  | The workflow execution is submitted to the selected pipeline for analysis                                     |
    | 4. Running    | The workflow execution is being analysed by the selected pipeline                                             |
    | 5. Completing | The analysis was successful and IRIDA Next is finalizing the workflow execution and its contents for the user |
    | 6. Completed  | The workflow execution is complete and ready for use                                                          |

  Error states:

    | State     | Description                                                                                |
    | :-------- | :----------------------------------------------------------------------------------------- |
    | Error     | An error occurred during analysis and the run is aborted                                   |
    | Canceling | The workflow execution was cancelled and IRIDA Next is in the process of canceling the run |
    | Canceled  | The workflow execution has successfully canceled                                           |

The current state of any workflow execution is shown on the workflow execution listing page.

<!-- TODO: Include the following headers with explanations and/or descriptions:
- States of Workflow Executions
- User Workflow Executions
  - Navigating to the user workflow executions page
  - Creating a user workflow execution
- Automated Workflow Executions
  - Navigating to the automated workflow executions page
  - Creating an automated workflow execution
-->
