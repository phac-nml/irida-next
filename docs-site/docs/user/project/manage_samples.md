---
sidebar_position: 4
id: manage_samples
title: Manage Samples
---

In IRIDA Next samples are stored inside of a project

## View Samples

Prerequisites:

- You must have access to the project either through membership, or through a namespace share

To view samples that the project contains:

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**

## Create Sample

Prerequisites:

- You must have access to the project either through membership, or through a namespace share
- You must have at least a **Maintainer** role

To create a new sample in a project:

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select **New Sample**
4. Enter the name of the sample in the **Name** field
5. Enter an optional description for the sample in the **Description** field
6. Select **Create sample**

## Update Sample

Prerequisites:

- You must have access to the project either through membership, or through a namespace share
- You must have at least a **Maintainer** role

To update sample details:

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the sample that you would like to edit
4. Select **Edit this sample**
5. Enter the name of the sample in the **Name** field
6. Enter an optional description for the sample in the **Description** field
7. Select **Update sample**

## Delete Sample

Prerequisites:

- You must have access to the project either through membership, or through a namespace share
- You must have at least an **Owner** role

To remove a sample:

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the sample that you would like to remove
4. Select **Remove**

## Transfer samples

Prerequisites:

- If you have a **Maintainer** role, you can only transfer samples to other projects which share a common ancestor to the project from which you are transferring from.

  Otherwise:

- You must have access to the project from which you are transferring samples, and the project into which you are transferring either through membership, or through a namespace share
- You must have at least an **Owner** role in the project you are transferring from
- You must have at least a **Maintainer** role in the project you are transferring into

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the checkboxes for the samples that you would like to transfer
4. Select **Transfer samples**
5. From the transfer samples pop-up, select the project to which you would like to transfer the samples to, and select **Submit**

## View Sample files

Prerequisites:

- You must have access to the project either through membership, or through a namespace share

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. The table lists all the single-end and paired-end files which have been uploaded to the sample

## Upload Files to Samples

Prerequisites:

- You must have access to the project either through membership, or through a namespace share
- You must have at least a **Maintainer** role

To upload files to a sample:

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select **Upload Files**
4. From the dialog, select **Choose files**
5. Select the files you would like to upload. Multi file selection is enabled
6. Select **Upload**

## Delete Sample files

- You must have access to the project either through membership, or through a namespace share
- You must have an **Owner** role

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. To delete multiple files, select the checkboxes for the files you would like to delete, then click **Delete Files**
4. To delete individual single end and paired-end reads, select **Delete** for the files you would like to delete.

## Concatenate Sample files

- You must have access to the project either through membership, or through a namespace share
- You must have an **Maintainer** role
- Files of the same type (single-end or paired-end) and compression can be concatenated together

1. From the left sidebar, select **Projects**, select the project
2. From the left sidebar, select **Samples**
3. Select the checkboxes for the files you would like to concatenate, and select **Concatenate files**
4. In the dialog, the files to be concatenated are listed.
5. Enter the **Filename**. This will be the base name of the concatenated files.
6. Select the checkbox **Delete originals** if you would like to remove the original files after concatenation
7. Select **Concatenate**
