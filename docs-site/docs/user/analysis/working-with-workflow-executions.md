---
sidebar_position: 2
id: working-with-workflow-executions
title: Working with Workflow Executions
---

Learn how to use workflow executions in IRIDA Next

## View User Workflow Executions

There are two ways to navigate and view user workflow executions:

  * If you are currently viewing a project or group, click the dropdown on the left sidebar that contains the project or group name, and click **Workflow Executions** in the dropdown menu.
  * If you are not currently viewing a project or group, click **Workflow Executions** on the left sidebar.

This page will list all your workflow executions.

## View Automated Workflow Executions

Prerequisites:
  * You must have at least the Analyst role to the project with workflow executions.

To view automated workflow executions:
  1. Navigate to the [project](../project/projects/manage-projects#view-projects-you-have-access-to) containing the workflow executions
  2. Click **Workflow Executions**

This page will list all of the project's workflow executions.

## View Single Workflow Execution

To view a specific workflow execution:
  1. Follow the steps to view either the [user](../analysis/working-with-workflow-executions#view-user-workflow-executions) or [automated](../analysis/working-with-workflow-executions#view-automated-workflow-executions) workflow executions listing page
  2. Click the **ID** of the workflow execution you'd like to view

Each individual workflow execution will contain a summary, the parameters selected during set-up, and the output files once analysis has completed.

## Create A User Workflow Execution

Prerequisites:
  * A project must contain at least one sample, and that sample must have uploaded paired-end files.
  * You must have at least the Analyst role to the project or group you will create the workflow execution from.

To create a user workflow execution:
  1. Navigate to the [project](../project/projects/manage-projects#view-projects-you-have-access-to) or [group](../organization/groups/manage#view-groups) that contains the samples you'd like to analyse
  2. From the left sidebar, select **Samples**
  3. Click the checkbox of each sample you'd like to include in the analysis
  4. Click ![workflow_execution_btn](./assets/rocket_launch.svg)
  5. Select a pipeline in the new pop-up
  6. The next pop-up contains a list of parameters for you to enter and/or confirm, as well as optional parameters to either give the workflow execution a name and whether you'd like to receive an e-mail notification when analysis is complete.

## Set-up Automated Workflow Executions

Prerequisites:
  * A project and at least the Maintainer role for this project.

To set-up automated workflow executions:
  1. Navigate to the [project](../project/projects/manage-projects#view-projects-you-have-access-to) which you'd like to set up automated workflow executions
  2. From the left sidebar, select **Settings**
  3. In the **Settings** dropdown menu, select **Automated Workflow Executions**
  4. Click **New automated workflow execution**
  5. Select a pipeline in the new pop-up
  6. The next pop-up contains a list of parameters for you to enter and/or confirm, as well as optional parameters to give the workflow execution a name, whether you'd like to receive an e-mail notification when analysis is complete, and whether you'd like the project's samples to update with analysis results.

Once set-up, each time paired-end files are uploaded to a sample belonging to this project, a workflow execution with these selected parameters will execute.
