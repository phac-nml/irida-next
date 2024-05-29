---
sidebar_position: 2
id: working-with-exports
title: Working with Exports
---

## View Exports

There are two ways to navigate and view your exports:

* If you are currently viewing a project or group, click the dropdown on the left sidebar that contains the project or group name, and click **Data Exports** in the dropdown menu.
* If you are not currently viewing a project or group, click **Data Exports** on the left sidebar.

The exports page will list all your current exports.

## View Single Export

To view a single export:
  1. Follow the [steps](../export/working-with-exports#view-exports) to navigate to the exports page.
  2. Click either the **ID** or **name** of the desired export.

Each individual export will contain a summary and a preview tab. The preview tab contains an overview of the export contents, and is only available once the export status is **Ready**.

## Create Sample Export

Prerequisites:
  * A project must contain at least one sample, and that sample must have uploaded files.
  * You must have at least the Analyst role to the project and/or group you will create the export from.

To create a sample export:
  1. Navigate to the [project](../project/projects/manage-projects#view-projects-you-have-access-to) or [group](../organization/groups/manage#view-groups) that contains the samples you would like to export.
  2. On the left sidebar, click **Samples**.
  3. In the table containing the samples, click the **checkbox** to the left of each sample you'd like to export.
  4. Click the **Create Export** button.
  5. A pop-up will appear asking if you'd like to give the export a name and whether you'd like to receive an e-mail notification when the export is ready to download. Neither of these are required to create the export.

## Create Analysis Export from a User Workflow Execution

Prerequisites:
  * A workflow execution with the completed state.

To create an analysis export from a user workflow execution:
  1. Navigate to the workflow executions page.
    <!-- TODO: Replace navigate with link to workflow executions view steps when available -->
  2. In the table containing the workflow executions, click on the workflow execution you'd like to export.
  3. Click the **Create Export** button.
  4. A pop-up will appear asking if you'd like to give the export a name and whether you'd like to receive an e-mail notification when the export is ready to download. Neither of these are required to create the export.

## Create Analysis Export from an Automated Workflow Execution

Prerequisites:
  * Project that has at least one automated workflow execution with a completed state.
  * You must have at least the Analyst role for the project containing the automated workflow execution.

To create an analysis export from an automated workflow execution:
  1. Navigate to the [project](../project/projects/manage-projects#view-projects-you-have-access-to) containing the workflow execution.
  2. In the left sidebar, click the **Workflow Executions** link.
  3. In the table containing the workflow executions, click on the workflow execution you'd like to export.
  4. Click the **Create Export** button.
  5. A pop-up will appear asking if you'd like to give the export a name and whether you'd like to receive an e-mail notification when the export is ready to download. Neither of these are required to create the export.

## Download Export

Prerequisites:
  * The export has a **Ready** status

To download an export, either:
  * Navigate to the export listing page and click the **Download** link of the export you'd like to download
  * Navigate to the export page and click the **Download** button.

## Delete Export

To delete an export, either:
  * Navigate to the export listing page and click the **Delete** link of the export you'd like to delete
  * Navigate to the export page and click the **Remove** button.


