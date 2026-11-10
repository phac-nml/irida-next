---
sidebar_position: 2
id: sample-sequence-data
title: Manage Sample Sequence Data
---

Sequence data can be uploaded individually (manually) or in batches (via external applications). IRIDA Next does not automatically create samples for uploaded sequence files, you must create them prior to uploading your sequence data.

## View Sample Data Files
- **Guest** role (at minimum) in the project.

**Note:** A user or bot account with the **Uploader** role can only view samples via the API.

To view sample data files:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the samples that you would like to view.
3.	From the left sidebar, select **Samples**.
4.	The **Samples** page will open. If you are within a project, the page shows a list of all samples contained within the project. If you are within a group, the page shows a list of all samples contained within <u>all projects</u> within that group and its subgroups.
5.	Click on the **Sample PUID** of the sample that you’re interested in.
6.	The sample’s page will open, showing a list of all files that have been uploaded to the sample. All types of sample files are shown in this list, including sequence files and pipeline results files.


## Upload Sequence Files to Samples

This method is useful for uploading a single fastq read set to a sample.

Prerequisites:

- **Maintainer** role (at minimum) in the project.

To upload files to a sample:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample that you would like to upload a sequence file to.
3.	From the left sidebar, select **Samples**.
4.	Select the **Sample PUID** of the sample that you would like to upload a sequence file to.
5.	Select **Upload Files**.
6.	From the dialog, select **Choose files**.
7.	Select the files you would like to upload and select **Open**. Multi-file selection is enabled, which allows selection of two files for paired-end reads, etc.
8.	Select **Upload**.


## Concatenate Sample Sequence Files

IRIDA Next supports the concatenation of sequence files as long as they are the same type of file (e.g. single-end or paired-end) and format of compression (e.g. fastq or fastq.gz).

Prerequisites:
- **Maintainer** role (at minimum) in the project.

1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample with sequence files that you would like to concatenate.
3.	From the left sidebar, select **Samples**.
4.	Click on the **Sample Name** of the sample that you’re interested in. The sample will open to the **Sample>Files** tab.
5.	Select the checkboxes beside the files that you would like to concatenate.
6.	Click the **Concatenate Files** button.
7.	In the pop-up window, review the list of files to be concatenated. Type a **Filename** for the concatenated file.
8.	Select the checkbox **Delete originals** if you would like to remove the original files after concatenation.
9.	Select **Concatenate**.
10.	Once completed, a dialogue box will appear in the top right corner of the screen confirming that the concatenation was successful. The new concatenated file name will be included in the file list and the original files will be removed (if checkbox was selected in step 8).


## Download Sample Data Files

Prerequisites:
- **Maintainer** role (at minimum) in the project.

To download sample data files:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample with files that you would like to download.
3.	From the left sidebar, select **Samples**.
4.	Click on the **Sample PUID** of the sample that you’re interested in. The download will begin in your browser.


## Delete Sample Data Files

Prerequisites:
- You must have an **Owner** role in the project.

To delete sample data files:
1.	From the left sidebar, select **Projects** or **Groups**.
2.	Select the project containing the sample with files that you would like to delete.
3.	From the left sidebar, select **Samples**.
4.	Click on the **Sample PUID** of the sample that you’re interested in.
5.	Select the checkbox(es) for the file(s) that you would like to delete, then click **Delete Files**.

