---
sidebar_position: 3
id: sample-metadata
title: Sample Metadata
---

Metadata can be added to samples to give them any additional information required by users.

A sample cannot have metadata with the same key, and metadata added by an analysis cannot be overwritten by a user.

## View Metadata

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Click the toggle beside **Metadata**.

The samples table will update with all the samples' metadata.

To view individual sample metadata:

1. Select the sample
2. Click the **Metadata** tab

## Add Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample added to the project

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the sample
4. Click the **Metadata** tab
5. Click **Add Metadata**

A dialog will pop-up where you can add new metadata.

## Update Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample with existing metadata added to the project

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the sample
4. Click the **Metadata** tab
5. Click the **Update** link of the metadata you'd like to update

A dialog will pop-up where you can update the metadata.

## Learn About Importing Metadata

Importing metadata allows you to add multiple metadata fields to multiple samples all at once. This requires a spreadsheet in .csv, .xls, or .xlsx format.

An example of the expected format of spreadsheet is the following:

| Sample Name | MetadataField1 | MetadataField2 | MetadataField3 |
| :---------- | :------------- | :------------- | :------------- |
| Sample 1    | value1         | value2         | value3         |
| Sample 2    | value4         | value5         | value6         |

This will add the following:

| Sample 1                |
| :---------------------- |
| Key            | Value  |
| :------------- | :----- |
| MetadataField1 | value1 |
| MetadataField2 | value2 |
| MetadataField3 | value3 |

| Sample 2                |
| :---------------------- |
| Key            | Value  |
| :------------- | :----- |
| MetadataField1 | value4 |
| MetadataField2 | value5 |
| MetadataField3 | value6 |

You are required to have a column that contains a sample identifier. The identifier is case-sensitive and can be either the sample name or ID.

**An important note:** When importing a metadata spreadsheet, you will be asked if you'd like to **Ignore empty values**. If this is selected, any metadata fields without an associated value will simply not be added to the sample. However, if this not selected, any samples with the metadata key and empty value will be **deleted**.

For example, if the metadata above was imported and added to Sample 1 and Sample 2, and the following spreadsheet was then imported:

| Sample Name | MetadataField1 | MetadataField2 | MetadataField3 |
| :---------- | :------------- | :------------- | :------------- |
| Sample 1    |                | newValue2      | newValue3      |
| Sample 2    | newValue4      |                | newValue6      |

This would result in the following sample metadata:
- If **Ignore empty values** was **checked**:

| Sample 1                   |
| :------------------------- |
| Key            | Value     |
| :------------- | :-------- |
| MetadataField1 | value1    |
| MetadataField2 | newValue2 |
| MetadataField3 | newValue3 |

| Sample 2                   |
| :------------------------- |
| Key            | Value     |
| :------------- | :-------- |
| MetadataField1 | newValue4 |
| MetadataField2 | value5    |
| MetadataField3 | newValue6 |

- If **Ignore empty values** was **not checked**:

| Sample 1                   |
| :------------------------- |
| Key            | Value     |
| :------------- | :-------- |
| MetadataField2 | newValue2 |
| MetadataField3 | newValue3 |

| Sample 2                   |
| :------------------------- |
| Key            | Value     |
| :------------- | :-------- |
| MetadataField1 | newValue4 |
| MetadataField3 | newValue6 |

## Steps to Import Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample added to the project

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Click **Import Metadata**

A dialog will pop-up to select the spreadsheet to be imported. After selecting the file, identify which column contains the sample identifier and whether you'd like to [Ignore empty values](sample-metadata#learn-about-importing-metadata)

## Delete Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample with existing metadata added to the project

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the sample
4. Click the **Metadata** tab
5. Click the checkboxes of the metadata you'd like to delete.
6. Click **Delete Metadata**
