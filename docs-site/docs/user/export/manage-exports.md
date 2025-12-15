---
sidebar_position: 2
id: manage-exports
title: Manage Exports
---

## View Exports

There are two ways to navigate and view your exports:

* If you are currently viewing a Project or Group, click the dropdown on the left sidebar that contains the project or group name, and click **Data Exports** in the dropdown menu.
* If you are not currently viewing a Project or Group, click **Data Exports** on the left sidebar.

The exports page will list all of your current exports.

## View Single Export

To view a single export:
  1. Follow the [steps](../export/working-with-exports#view-exports) to navigate to the exports page.
  2. Click either the **ID** or **name** of the desired export.

Each individual export will contain a summary tab. Sample and Analysis exports will also have a preview tab available. The preview tab contains an overview of the export contents, and is only available once the export status is **Ready**.

## Create Sample Export

Prerequisites:
  * A project must contain at least one sample, and that sample must have uploaded files.
  * **Analyst** role (at minimum) in the project and/or group you will create the export from.

To create a sample export:
1. Navigate to the **Project** or **Group** that contains the samples you would like to export.
2. From the left sidebar, select **Samples**.
3. Click the **checkbox** of each sample you would like to export.
4. Click **Create Export**.
5. In the dropdown, select **Sample Export**.
6. A pop-up will appear asking the following:
   - The file formats you'd like to include within the export. This allows you to filter out any file formats you do not wish to export. You are required to include at least one file format to create an export.
   - If you'd like to give the export a name (not required).
   - If you'd like to receive an e-mail notification when the export is ready to download (not required).

## Create Linelist Export

Prerequisites:
  * A project must contain at least one sample, and that sample must contain metadata.
  * **Analyst** role (at minimum) in the project and/or group you will create the export from.

To create a sample linelist export:
1. Navigate to the **Project** or **Group** that contains the samples you would like to export.
2. From the left sidebar, select **Samples**.
3. Click the **checkbox** of each sample you would like to export.
4. Click **Create Export**.
5. In the dropdown, select **Linelist Export**.
6. A pop-up will appear asking the following:
   - The metadata fields you'd like to include within the export. This allows you to filter out any metadata fields you do not wish to export. You are required to include at least one metadata field to create an export.
   - The file format of the export.
   - If you'd like to give the export a name (not required).
   - If you'd like to receive an e-mail notification when the export is ready to download (not required).

## Create Analysis Export from a User-Launched Workflow Execution

Prerequisites:
  * A workflow execution with the completed state.

To create an analysis export from a user-launched workflow execution:
  1. Navigate to the [Workflow Executions Page](../analysis/working-with-workflow-executions#view-user-workflow-executions).
  2. Click the workflow execution you would like to export.
  3. Click **Create Export**.
  4. A pop-up will appear asking if you'd like to give the export a name and whether you'd like to receive an e-mail notification when the export is ready to download. Neither of these are required to create the export.

## Create Analysis Export from an Automated Workflow Execution

Prerequisites:
  * Project that has one or more automated workflow executions with a completed state.
  * **Analyst** role (at minimum) for the project containing the automated workflow execution.

To create an analysis export from an automated workflow execution:
  1. Navigate to the Project containing the workflow execution.
  2. From the left sidebar, click **Workflow Executions**.
  3. Click the workflow execution you'd like to export.
  4. Click **Create Export**.
  5. A pop-up will appear asking if you'd like to give the export a name and whether you'd like to receive an e-mail notification when the export is ready to download. Neither of these are required to create the export.

## Download Export

Prerequisites:
  * The export has a **Ready** status.

To download an export, either:
  * Navigate to the export listing page and click the **Download** link of the export you would like to download, or
  * Navigate to the export page and click the **Download** button.

## Delete Export

To delete an export:
  * In the **Your Work** menu, click **Data Exports** on the left sidebar.
  * Either:
      * In the **export list**, find the export you would like to delete and select **Delete**.
      * Click either the **ID** or **Name** of the relevant export to open it. Click the **Delete** button.

**Note:** All exports will automatically delete after 3 days.


