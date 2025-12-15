---
sidebar_position: 2
id: manage-workflow-executions
title: Manage Workflow Executions
---
It is important to note that there are two types of workflow executions in IRIDA Next:
1)	**User-launched Workflow Executions**
2)	**Automated Workflow Executions**

**User-launched Workflow Executions** are only visible by the user that created them or users they were shared with. By default, other users within the same projects and/or groups where the pipeline was run cannot see these workflow executions or their results files.

**Automated Workflow Executions** belong to the project they were created in. Once set-up, Automated Workflow Executions are performed on all newly uploaded paired-end files within that project.  Automated Workflow Executions are accessible to all project members who have at least the **Analyst** role in the project.


## View Workflow Executions

Workflow execution records and results files can be viewed in different locations. The location of the information depends on two factors:
1)	**Who** launched the workflow (yourself, another user, or a bot) and
2)	**Where** the workflow was launched from (within a group or within a project)

A visual is available in Locate Workflow Execution Records to help you locate the different workflow executions.

## View User-Launched Workflow Executions
There are two ways to navigate and view user-launched workflow executions:
1.	If you are currently viewing a project or group, click the dropdown on the left sidebar that contains the project or group name, and click **Workflow Executions** in the dropdown menu.
    *    This page will list all workflow executions that you have created within that project or group.
2.	Under the **Your work** menu, click **Workflow Executions** on the left sidebar.
    *	This page will list all workflow executions that you have created within IRIDA Next.
    *	To determine which project or group a workflow execution is associated with, click on the **ID**. In the **Summary** tab, you will find one of “**Run from Project**”, “**Run from Group**”, “**Shared with Group**” or “**Shared with Group**” with the **Name** and **PUID** included.

    •	Once the workflow execution of interest has been located, click the **ID** to view. Each individual workflow execution contains a summary, the parameters selected during set-up, a samplesheet with input files, and output files once analysis has completed.



## View Automated Workflow Executions

Prerequisites:
  * **Analyst role** (at minimum) in the project with workflow executions.

To view automated workflow executions:
  1. Navigate to the **Project** containing the workflow executions.
  2. In the left sidebar, select **Workflow Executions**. This page will list all of the project's workflow executions.
3.	Once the workflow execution of interest has been located, click the **ID** to view. Each individual workflow execution contains a summary, the parameters selected during set-up, a samplesheet with input files, and output files once analysis has completed.

## Create User-Launched Workflow Executions
Prerequisites:
* A project with one or more samples.
* **Analyst** role (at minimum) in the project.

To create a user-launched workflow execution:
1.	Navigate to the **Project** or **Group** that contains the samples you would like to analyse.
2.	From the left sidebar, select **Samples**.
3.	Click the **checkbox** beside each sample that you would like to include in the analysis.
4.	Click the **Launch Workflow** button.
5.	In the pop-up window, select a **Pipeline**.
6.	In the next pop-up window, you will find a list of parameters for you to enter and/or confirm. This list includes parameters specific to the selected pipeline, along with optional parameters such as workflow name, e-mail notification, and sample updates upon workflow completion.

**Note:** Analysts do not have write permissions for metadata and therefore cannot select the option to update samples with results.

## Set-up Automated Workflow Executions
Prerequisites:

*	A project and the Maintainer role for this project (at minimum).

**As of November 2025, only automation workflow executions of Mikrokondo are supported.**

To set-up automated workflow executions:
1.	Navigate to the **Project** that requires automated workflow execution set-up.
2.	From the left sidebar, select **Settings**.
3.	In the Settings dropdown menu, select **Automated Pipelines**.
4.	Click **New automated pipeline**.
5.	In the pop-up window, select a **Pipeline**.
6.	In the next pop-up window, you will find a list of parameters for you to enter and/or confirm. This list includes parameters specific to the selected pipeline, along with optional parameters such as workflow name, and e-mail notification. **It is important to select “sample updates upon workflow completion” in order to have results saved to sample records.**

**Note:** Once set-up, each time paired-end files are uploaded to a sample belonging to this project, a workflow execution with these selected parameters will execute.

## View Workflow Execution Progress

While a workflow execution is running, it will go through numerous states to provide feedback on its progress.The current state of any workflow execution is shown on the relevant workflow execution page (refer to [View Workflow Executions](../analysis/working-with-workflow-executions)).

  States for a successful workflow execution (in order):

  | State      | Description                                                                                                                 |
  | :--------- | :-------------------------------------------------------------------------------------------------------------------------- |
  | New        | This is the initial state acknowledging that the workflow execution was successfully created and the files are being prepared for analysis. |
  | Prepared   | Files were successfully prepared and submission to the selected pipeline is underway.                                            |
  | Submitted  | The workflow execution was submitted to the selected pipeline.                                                               |
  | Running    | The workflow execution is being executed by the selected pipeline.                                                           |
  | Completing | The analysis was successful and IRIDA Next is finalizing the workflow execution for the user.                                |
  | Completed  | The workflow execution is complete and ready for the user.                                                                   |

  Error states:

  | State     | Description                                                                                |
  | :-------- | :----------------------------------------------------------------------------------------- |
  | Error     | An error occurred during analysis and the run was aborted.                                  |
  | Canceling | The workflow execution was canceled and IRIDA Next is in the process of canceling the run.  |
  | Canceled  | The workflow execution successfully canceled.                                               |
  | Disabled  | The automated workflow will no longer execute when new paired-end files are uploaded to a sample in the project.                                                |


## Delete a User-Launched Workflow Execution

1.	Navigate to the relevant **Workflow Executions** page (refer to [View Workflow Executions](../analysis/working-with-workflow-executions)).
2.	Locate the relevant workflow execution(s) and click the **checkbox** beside the ID.
3.	Click the **Delete Workflow Executions** button.
4.	In the pop-up window, review the workflow information and click **Confirm**.

**Note:** Deleting completed workflow execution records does not delete the associated results files. Only non-shared workflow executions that are in the Completed, Canceled, and Error states will be deleted.

## Delete an Automated Workflow Execution
1.	Navigate to the relevant **Project**.
2.	From the left sidebar, select **Settings**.
3.	In the **Settings** dropdown menu, select **Automated Pipelines**.
4.	Locate the workflow execution of interest and select **Delete** under the Actions column.
5.	Select **Confirm** in the pop-up window.

**Note:** Deleting an automated workflow execution does not delete the associated results files. Only non-shared workflow executions that are in the Completed, Canceled, and Error states will be deleted.

