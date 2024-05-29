---
sidebar_position: 1
id: getting-started
title: Getting Started
---

In IRIDA Next, you can download files from multiple samples or all files associated with a workflow execution at once by creating a data export.

## Export Types

There are two types of exports in IRIDA Next:

| Export Type      | Description                                                                                                                           |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| Sample           | Allows users to select any number of samples belonging to either a group or project and download all the associated files.    |
| Analysis         | Allows users to download all files associated with a workflow execution.                                                      |

## Requirements

The following is required to create an export:
* Sample Export
  * Project that has at least one associated sample, and files uploaded to the sample.
  * At least the Analyst role for the Project or Group containing the samples for export.
* Analysis Export
  * User Workflow Execution
    * A user workflow execution in the completed state
  * Automated Workflow Execution
    * Project that has at least one automated workflow execution in the completed state.
    * At least the Analyst role for the project containing the automated workflow execution.

## Export Contents

Exports allow users to download their files from IRIDA Next with a single click. Follow these [steps](../export/working-with-exports) to learn how to work with exports.

The files are added to a single, compressed folder. In addition to the exported files selected by the user, two additional files are included:
  * Each export includes a **manifest.json** file that contains an overview of what's included in the export.
  * Each analysis export includes a **summary.txt.gz** file that contains the pipeline summary.

## Export Statuses

Exports will have either a **Processing** or **Ready** status assigned to them.
  * When an export is **Processing**, IRIDA Next is in the process of creating your export and, therefore, your export is not available to download.
  * Once the export status is **Ready**, the export is ready to download. A [preview](../export/working-with-exports#view-single-export) of the export contents is also viewable on IRIDA Next once the export status is **Ready**.

After the export status is set to **Ready**, you will have **3 business days** to download the export before it is automatically deleted. You can choose to receive an [e-mail](../export/working-with-exports#create-sample-export) when creating the export to ensure you do not miss the download window.

