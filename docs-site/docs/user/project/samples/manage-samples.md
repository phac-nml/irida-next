---
sidebar_position: 1
id: manage-samples
title: Manage Samples
---

In IRIDA Next, samples are stored exclusively within projects. Each sample can have multiple files attached, including sequence data or assembly files. There are no limitations to the file types that can be added to samples. Detailed metadata can also be added to each sample.

## View Samples

Prerequisite:

- **Guest** role in the project (at minimum).

**Note:** A user or bot account with the **Uploader** role can only view samples via the API.

To view samples:

1. From the left sidebar, select **Projects** or **Groups**.
2. Select the project containing the samples that you would like to view.
3. From the left sidebar, select **Samples**.
4. The **Samples** page will open. If you are within a project, the page shows a list of all samples contained within the project. If you are within a group, the page shows a list of all samples contained within <u>all projects</u> within that group and its subgroups.

Refer to the following sections for information on viewing:
1. Sample data files
2. Sample metadata

## Create a Sample

Prerequisites:

- **Maintainer** role in the project (at minimum).

**Note:** A user or bot account with the **Uploader** role <u>can</u> create samples through the API.

To create a new sample in a project:

1. From the left sidebar, select **Projects**. You <u>cannot</u> create samples from the group level view.
2. Select the project that you would like to create a sample in.
3. From the left sidebar, select **Samples**.
4. Click **Sample Actions** and select **New Sample** from the drop-down menu.
5. Enter the name of the sample in the **Name** field.
6. Enter an optional description for the sample in the **Description** field.
7. Select **Create sample**.

## Edit a Sample Name

Prerequisites:

- **Maintainer** role in the project (at minimum).

**Note:** A user or bot account with the **Uploader** role <u>can</u> create samples through the API.

To edit a sample name or description:

1. From the left sidebar, select **Projects**. You <u>cannot</u> edit samples from the group level view.
2. Select the project with the sample that you would like to edit.
3. From the left sidebar, select **Samples**.
4.	Click on the **SAMPLE PUID** to select the sample.
5.	Click the **Edit this sample** button.
6. Enter the name of the sample in the **Name** field.
7. Enter an optional description for the sample in the **Description** field.
8. Select **Update sample**.

## Delete a Sample
Deleting a sample will permanently remove that sample from the project. This action cannot be undone. It is strongly recommended that rather than routinely deleting samples, you create a "Recycling Bin Project" to temporarily store samples destined for deletion. It is recommended that the Recycling Bin Project be reviewed and emptied by a designated individual at regular intervals.

Prerequisites:
- You must have an **Owner** role in the project.

To delete samples:
1.	From the left sidebar, select **Projects**. You <u>cannot</u> delete samples when viewing at the group level.
2.	Select the project with the sample that you would like to delete.
3.	From the left sidebar, select **Samples**.

To delete a single sample:

4.	Click on the **SAMPLE PUID** to select the sample.
5.	Select **Remove**.
6.	In the pop-up window, click the **Remove** button to confirm sample deletion.

To delete multiple samples:

4.	Select the checkboxes beside the samples that you would like to transfer.
5.	Click **Sample Actions** and select **Delete Samples** from the drop-down menu.
6.	In the pop-up window, review your samples selected for deletion and click **Confirm**.



## Transfer Samples

Transferring a sample will move that sample from its current location to a destination project of your choice. This sample will no longer exist in the original location. All files and metadata associated with the sample at the time of transfer will be conserved in the new location.

Prerequisites:

- **Owner** role in the project you are transferring from.
- **Maintainer** role (at minimum) in the project you are transferring to.

**Note:** If you have a **Maintainer** role in the project you are transferring from, you <u>can</u> transfer samples to other projects with a shared common ancestor.

To transfer samples into another project:

1. From the left sidebar, select **Projects**. You <u>cannot</u> transfer samples when viewing at the group level.
2. Select the project with the sample that you would like to transfer.
3. From the left sidebar, select **Samples**.
4. Select the checkboxes beside the samples that you would like to transfer.
5. Click **Sample Actions** and select **Transfer Samples** from the drop-down menu.
6.	In the pop-up window, select the **Project** to transfer samples to and click **Submit**.
7.	A pop-up window with a progress bar will appear, followed by message indicating the success of the transfer. Click **OK**.

**TIP:** Check out the **Activity** tab on the left sidebar to view a history of transfers and other activities within a group or project.


## Copy Samples
Copying samples will create a duplicate sample in the destination project of your choice. This duplicate sample will contain all files and metadata associated with the sample at the time of copying.

**Note:** Any changes made to either the copy or the original sample are unique to that specific sample.

Prerequisites:
- **Maintainer** role (at minimum) in the project you are copying from.
- **Maintainer** role (at minimum) in the project you are copying to.

To copy samples into another project:

1.	From the left sidebar, select **Projects**. You <u>cannot</u> copy samples when viewing at the group level.
2.	Select the project with the sample that you would like to copy.
3.	From the left sidebar, select **Samples**.
4.	Select the checkboxes beside the sample(s) that you would like to copy.
5.	Click **Sample Actions** and select **Copy samples** from the drop-down menu.
6.	In the pop-up window, select the **Project to copy samples to** and click **Submit**.
7.	A pop-up window with a progress bar will appear, followed by message indicating that the sample(s) copied successfully. Click **OK**.
