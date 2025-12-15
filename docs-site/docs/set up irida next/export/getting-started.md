---
sidebar_position: 1
id: general-export-information
title: General Export Information
---

In IRIDA Next, you can download data from multiple samples or all files associated with a workflow execution at once by creating a data export.

## General Export Information

There are three types of exports in IRIDA Next:

| Export Type      | Description                                                                                                                           |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| Sample           | Allows users to select any number of samples belonging to either a group or project and download all the associated files.    |
| Linelist         | Allows users to select any number of samples belonging to either a group or project and download all the associated metadata. |
| Analysis         | Allows users to download all files associated with a workflow execution.                                                      |

## Requirements to Create an Export

The following is required to create an export:
* Sample Export
  * At minimum, the **Analyst** role for the Project or Group containing the samples for export.
  * Project containing one or more samples with files.

* Linelist Export
  * At minimum, the **Analyst** role for the Project or Group containing the samples for export.
  * Project containing at minimum one sample with metadata.

* Analysis Export
  * User-launched Workflow Execution
    * A user-launched workflow execution in the completed state.
  * Automated Workflow Execution
    * Project with one or more automated workflow execution(s) in the completed state.
    * At minimum, the **Analyst** role for the project containing the automated workflow execution.


## Contents of an Export


Sample and Analysis exports:
* The files are added to a single, compressed folder. In addition to the exported files selected by the user, three additional files are included:
  * Each export includes a **manifest.json** and **manifest.txt** file that contains an overview of what's included in the export.
  * Each analysis export includes a **summary.txt.gz** file that contains the pipeline summary.

Linelist exports:
* The export contents will be contained in a single file of the chosen format (.csv or .xlsx).

## Status of an Export

Exports will have either a **Processing** or **Ready** status assigned to them.
  * When an export is **Processing**, IRIDA Next is in the process of creating your export and, therefore, your export is not available to download.
  * Once the export status is **Ready**, the export is ready to download. A [preview](../export/working-with-exports#view-single-export) of the export contents for Sample and Analysis exports is also viewable on IRIDA Next once the export status is **Ready**.

**Note:** After the export status is set to **Ready**, you will have **3 business days** to download the export before it is automatically deleted. You can choose to receive an [e-mail](../export/working-with-exports#create-sample-export) when creating the export to ensure you do not miss the download window.

