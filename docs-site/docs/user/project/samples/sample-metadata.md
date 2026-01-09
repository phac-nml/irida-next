---
sidebar_position: 3
id: sample-metadata
title: Manage Sample Metadata
---
**Note:** Metadata added by an analysis cannot be overwritten by a user but it can be deleted.

## View Metadata

Prerequisites:

- **Guest** role (at minimum) in the project.

To view all metadata for samples within a project:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample(s) that you would like to view metadata for.
3.	From the left sidebar, select **Samples**.
4.	Click the **Metadata** button.
5.	Select **Show All Fields**. The samples table will update with all of the samples' metadata.

To view individual sample metadata:
1.	Select the **Sample PUID**.
2.	Click the **Metadata** tab.


## Add Metadata

Prerequisites:

- Maintainer role (at minimum) in the project.

To add metadata to a sample:
1. From the left sidebar, select **Projects** or **Groups**.
2. Select the project containing the sample that you would like to add metadata to.
3. From the left sidebar, select **Samples**.
4. Select the **Sample PUID**.
5. Click the **Metadata** tab.
6. Click **Add Metadata**.
7.	In the pop-up window, provide a name for the **new metadata field (Key)** and enter a **Value** into the text box.
8.	If you would like to add more than one new metadata field, select **Add Another Metadata Field**.
9.	When all text boxes are filled, click the **Add** button. The metadata field key will now appear under the **Metadata** tab.

## Import Metadata Spreadsheets
This section describes the addition of metadata to a sample using a spreadsheet. Using this method allows users to populate multiple metadata fields across multiple samples at the same time.

Prerequisites:

- Maintainer role (at minimum) in the project.

To import metadata:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the samples that you would like to add metadata to.
3.	From the left sidebar, select **Samples**.
4.	Click the **Sample Actions** button.
5.	In the drop-down list, select **Import Metadata**.
6.	In the pop-up window, select **Choose File** and locate the metadata spreadsheet for your samples. Select **Open**.

    **Note:** The metadata spreadsheet must be in .csv, .tsv, .xls, or .xlsx format. **The spreadsheet is required to have a column that contains a sample identifier.** The identifier is case-sensitive and can contain either the **Sample Name** or **Sample PUID**. **All column names must match existing Key fields within IRIDA Next exactly.** If field names differ, the metadata will not match to the correct field columns within IRIDA Next. Instead, new Key field columns will be created for those samples.

    An example of the required spreadsheet layout is shown below. For more information and helpful tips, see [Metadata Import](sample-metadata-import).

    | Sample Name | MetadataField1 | MetadataField2 | MetadataField3 |
    | :---------- | :------------- | :------------- | :------------- |
    | Sample 1    | value1         | value2         | value3         |
    | Sample 2    | value4         | value5         | value6         |

7.	In the pop-up window, select the **Sample Identifier Column** from a drop-down list. If there is an issue with the spreadsheet, a message in red text will appear within the pop-up window. For example “The uploaded spreadsheet contains no viable metadata”. If this occurs, review the layout of your sample spreadsheet and try again.
8.	Select the checkbox to **Ignore Empty Values** (should be preselected). **Note:** If Ignore Empty Values is <u>not</u> selected, any blank values in the uploaded file will replace existing values in IRIDA Next (i.e. data will be deleted if **Ignore Empty Values** is not checked).
9.	Click **Import Metadata**.

**Note:** A sample must exist in the target project to upload metadata to it. Otherwise, a **Could not find sample** error will appear.


# Modify Metadata
Modification of sample metadata can be complicated depending on the upload method of the metadata (either by user or through a workflow execution). This is intentional, to reduce the possibility of accidental modification of pipeline analysis results saved as metadata.

**User-derived metadata** is straightforward to modify. User-derived metadata includes metadata that has been:

- Manually entered by a user to the sample metadata tab,
- Uploaded to IRIDA Next  in a spreadsheet using the Upload Metadata function, or
- Uploaded through an external application.

**Pipeline-derived metadata** is not straightforward to modify. Pipeline-derived metadata includes:

- Metadata field values uploaded to samples using the Populate Metadata pipeline.
- Workflow execution results stored as sample metadata values.

## Modify User-Derived Metadata

Prerequisites:

- **Maintainer** role (at minimum) in the project.

To update sample metadata:

1. From the left sidebar, select **Projects** or **Groups**.
2. Select the project containing the sample with metadata that requires updating.
3. From the left sidebar, select **Samples**.
4.	Click the **Metadata** button and select **Show All Fields** from the drop-down menu.
5.	Users can either:
    - Modify metadata directly in the table by clicking on the relevant cells. (**Note:** Pipeline-derived values will not allow you to click on them.) **OR**
    - Modify metadata for one sample at a time in each sample’s metadata tab.
      - Select the **Sample PUID**.
      - Click the **Metadata** tab.
      - In the **Action** column, select **Update** in the row corresponding to the relevant metadata key.
      - In the pop-up window, edit the key or value fields and select **Update**.
6.	Either method will results in metadata updates that are visible right away.

## Modify Pipeline-Derived Metadata
Users cannot directly modify pipeline-derived metadata. However, pipelines can modify pipeline-derived metadata such as overwriting existing pipeline results. The steps below describe how to use the **Populate Metadata** pipeline to modify pipeline-derived metadata.
**Note:** Only one field and one value can be modified at a time using this method.

Prerequisites:

- **Maintainer** role (at minimum) in the project.

To update sample metadata:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample(s) with metadata that requires updating.
3.	From the left sidebar, select **Samples**.
4.	Check boxes beside the samples that require metadata modification.
5.	Click the **Launch workflow** button.
6.	Select the **Populate Metadata** pipeline.
7.	In the pop-up window:
    - Enter a **Name** for the workflow execution.
    - Under **Transformation options**, type the name of the field into the **- -populate_header** box and the value to populate into the **- - populate_value box**. For example: - -populate_header: YEAR  - -populate_value: 2025 will result in all selected samples having a YEAR field with value 2025.
    - Select check boxes beside **Update samples with analysis results** (required or your metadata will not be added) and **Receive an email notification when your analysis has completed** (optional).
    - Click the **Submit** button.
8.	Once the workflow execution status is **Completed**, the metadata entries will be visible.


## Delete Metadata

Prerequisites:

-  **Maintainer** role (at minimum) in the project.

To delete individual user-derived metadata values:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the samples that you would like to delete metadata from.
3.	From the left sidebar, select **Samples**.
4.	Select the **Sample PUID**.
5.	Click the **Metadata** tab.
6.	If you are deleting one metadata field:
    -  In the **Action** column, select **Delete** in the row corresponding to the relevant metadata key.
7.	If you are deleting multiple metadata key fields at once:
    - Select the check box beside each field and select the **Delete Metadata** button.
8.	In the pop-up window, click the **Confirm** button.


To delete user-derived metadata values across multiple samples:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample(s) with metadata that you would like to delete.
3.	From the left sidebar, select **Samples**.
4.	Click the **Metadata** button and select **Show All Fields** from the drop-down menu.
5.	Delete metadata directly in the table by clicking on the relevant cells (**Note:** Pipeline-derived values will not allow you to click on them.)
6.	In the pop-up window, click **Save**.

To delete pipeline-derived metadata values:
1.	Follow the directions to Import Metadata Spreadsheets.
2.	For the metadata field values that you would like to delete, ensure you leave the cells blank.
3.	Deselect the checkbox to **Ignore Empty Values**.
4.	Click **Import Metadata**.
