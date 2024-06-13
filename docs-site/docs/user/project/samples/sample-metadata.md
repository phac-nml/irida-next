---
sidebar_position: 3
id: sample-metadata
title: Sample Metadata
---

Metadata can be added to samples to give them any additional information required by users.

A sample cannot have metadata with the same key, and metadata added by an analysis cannot be overwritten by a user.

## View Metadata

1. From the left sidebar, select **Projects**
2. Select the project
3. From the left sidebar, select **Samples**
4. Click the toggle beside **Metadata**

The samples table will update with all the samples' metadata.

To view individual sample metadata:

5. Select the sample
6. Click the **Metadata** tab

## Add Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample added to the project

1. From the left sidebar, select **Projects**
2. Select the project
3. From the left sidebar, select **Samples**
4. Select the sample
5. Click the **Metadata** tab
6. Click **Add Metadata**

A dialog will pop-up where you can add new metadata.

## Update Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample with existing metadata added to the project

1. From the left sidebar, select **Projects**
2. Select the project
3. From the left sidebar, select **Samples**
4. Select the sample
5. Click the **Metadata** tab
6. Click the **Update** link of the metadata you'd like to update

A dialog will pop-up where you can update the metadata.

## Learn About Importing Metadata

Importing metadata allows you to add multiple metadata fields to multiple samples all at once. This requires a spreadsheet in .csv, .xls, or .xlsx format.

This is an example of the expected spreadsheet format:

  | Sample Name | MetadataField1 | MetadataField2 | MetadataField3 |
  | :---------- | :------------- | :------------- | :------------- |
  | Sample 1    | value1         | value2         | value3         |
  | Sample 2    | value4         | value5         | value6         |

The following metadata will be added:

  - Sample 1:

    | Key            | Value  |
    | :------------- | :----- |
    | MetadataField1 | value1 |
    | MetadataField2 | value2 |
    | MetadataField3 | value3 |

  - Sample 2:

    | Key            | Value  |
    | :------------- | :----- |
    | MetadataField1 | value4 |
    | MetadataField2 | value5 |
    | MetadataField3 | value6 |

When creating the spreadsheet, you are required to have a column that contains a sample identifier. The identifier is case-sensitive and can contain either the sample names or IDs.

**An important note:** When importing a metadata spreadsheet, you will be asked if you'd like to **Ignore empty values**. If this is **selected**, any metadata fields without an associated value will be ignored and those metadata keys will not be removed from the sample if present. However, if this **not selected**, any samples with the metadata key and empty value will be **deleted**.

For example, if the metadata above was imported and added to Sample 1 and Sample 2, and the following spreadsheet was then imported:

  | Sample Name | MetadataField1 | MetadataField2 | MetadataField3 | MetadataField4 |
  | :---------- | :------------- | :------------- | :------------- | :------------- |
  | Sample 1    |                | newValue2      | newValue3      | anotherValue1  |
  | Sample 2    | newValue4      |                | newValue6      | anotherValue2  |

This would result in the following sample metadata:
- If **Ignore empty values** was **checked**:

  - Sample 1:

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | value1        |
    | MetadataField2 | newValue2     |
    | MetadataField3 | newValue3     |
    | MetadataField4 | anotherValue1 |

  - Sample 2:

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | newValue4     |
    | MetadataField2 | value5        |
    | MetadataField3 | newValue6     |
    | MetadataField4 | anotherValue2 |

- If **Ignore empty values** was **not checked**:

  - Sample 1:

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField2 | newValue2     |
    | MetadataField3 | newValue3     |
    | MetadataField4 | anotherValue1 |

  - Sample 2:

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | newValue4     |
    | MetadataField3 | newValue6     |
    | MetadataField4 | anotherValue2 |

## Steps to Import Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample added to the project

1. From the left sidebar, select **Projects**
2. Select the project
3. From the left sidebar, select **Samples**
4. Click **Import Metadata**

A dialog will pop-up to select the spreadsheet to be imported. After selecting the spreadsheet file, identify which column contains the sample identifier and whether you'd like to [Ignore empty values](sample-metadata#learn-about-importing-metadata)

## Delete Metadata

Prerequisites:

- You must have at least a **Maintainer** role for the sample's project
- A sample with existing metadata added to the project

1. From the left sidebar, select **Projects**
2. Select the project
3. From the left sidebar, select **Samples**
4. Select the sample
5. Click the **Metadata** tab
6. Click the checkboxes of the metadata you'd like to delete.
7. Click **Delete Metadata**
