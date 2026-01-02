# About IRIDA Next
IRIDA Next is a cloud-based data management system designed to securely store data, enhance data sharing, and facilitate bioinformatic workflows.

## Data Organizational Structure
IRIDA Next uses a hierarchical data organizational structure consisting of groups, projects, and samples:

- **Groups:** Top-level containers that manage related projects and subgroups.
- **Projects:** Store and organize samples for analysis and sharing.
- **Samples:** Hold sequence files and metadata for genomic analysis.

This structure supports flexible data organization, sharing, and inheritance of member permissions from parent groups to subgroups and projects.

## Sample and Metadata Management
Samples are created within projects and can have files and detailed metadata attached. Data upload can be completed manually in IRIDA Next, or using pipelines or external applications. Metadata can be added manually, using pipelines, imported via spreadsheets, or managed using external applications.

## Searching, Filtering, and Auditing
IRIDA Next provides robust tools for searching and filtering samples using identifiers or advanced metadata queries. Auditing features enable tracking of changes to groups, projects, and samples, supporting laboratory accreditation and data integrity.

## Workflow Execution and Analysis
Analysis workflows are executed through the integrated Workflow Execution Service (WES), which supports Nextflow pipelines. Users can run ad hoc or automated workflows, with results stored as metadata and output files within IRIDA Next.

## Data Export and Sharing
Multiple export options are available:
- **Sample Exports:** Download files and data associated with user-selected samples.
    - Format: The export is a compressed folder with user-selected sample files (such as .csv, .fasta, .fastq, .genbank, .json) plus three overview files: manifest.json, manifest.txt, and summary.txt.gz.
- **Linelist Exports:** Export sample metadata in CSV or Excel format. **Note:** Pipeline results are incorporated as sample metadata and included in linelist exports.
    - Format: The export is a single .csv or .xlsx file containing user-selected metadata fields for user-selected samples.
- **Analysis Exports:** Retrieve files associated with a workflow execution.
    - Format: The export is a compressed folder with all sample files included in the workflow execution (such as .csv, .fasta, .fastq, .genbank) plus three overview files: manifest.json, manifest.txt, and summary.txt.gz.

Data can be exported at any time. Once generated, data exports are available to download for a limited time (3 days) and can be previewed within IRIDA Next. **Note:** After 3 days users simply must go through the process of creating their export again (no data is lost).

## Data Visualization and Reporting
Data exported from IRIDA Next can be easily incorporated into a program’s existing reporting tools.

## User Roles and Permissions
Access control in IRIDA Next is managed through roles assigned to individual users or groups:
- **Guest:** Limited access, primarily for viewing (rarely used).
- **Uploader:** API-based access for data upload.
- **Analyst:** Can view and analyze data.
- **Maintainer:** Can modify and transfer data, manage members, and upload files.
- **Owner:** Full control, including deletion of groups/projects.

Users are automatically **Owners** of the groups and projects that they create. Other users do not have access to these groups and projects until they are specifically granted access by the **Owner**.

The only exception is if a user already has access to the parent group that the project or subgroup was created in. In that case, the user automatically has access to all nested projects and subgroups subsequently created within that group. This is because permissions are inherited hierarchically, which ensures streamlined data management.

Data management responsibilities in IRIDA Next fall entirely on the users. Sharing features allow temporary or indefinite access to groups and projects, with configurable expiration dates.
