---
sidebar_position: 2
id: member-permissions
title: Permissions and Roles
---
##
When you add a user to a project or group, you assign each member a role. This role determines the actions that members are permitted to perform within IRIDA Next.

# Roles

The available roles are:

- Guest
- Uploader
- Analyst
- Maintainer
- Owner

A user assigned the **Guest** role has the least permissions, and the **Owner** has the most.

# Permissions

A comprehensive list of all permissions and roles is provided below based on **Group**, **Project**, and **Sample** Level.

## Group Level Permissions
| Action                       | Guest | Uploader | Analyst | Maintainer | Owner |
| :--------------------------- | :---- | :------- | :------ | :--------- | :---- |
| Create Subgroups   |       |          |         | ✓          | ✓     |
| Edit Group      |       |          |         | ✓          | ✓     |
| Delete Group    |       |          |         |            | ✓     |
| View Group      | ✓     | ✓ (1)    | ✓       | ✓          | ✓     |
| Transfer Group  |       |          |         |            | ✓     |
| Add Group Member             |       |          |         | ✓(2)       | ✓     |
| Edit Group Member            |       |          |         | ✓(2)       | ✓     |
| Remove Group Member          |       |          |         | ✓(2)       | ✓     |
| Add Bot Account             |       |          |         | ✓          | ✓     |
| Remove Bot Account         |       |          |         | ✓          | ✓     |
| View Group Members           | ✓     |          | ✓       | ✓          | ✓     |
| View Group Files             |       |          | ✓       | ✓          | ✓     |
| Download Group Files             |       |          | ✓       | ✓          | ✓     |
| Upload Group Files           |       |          |         | ✓          | ✓     |
| Delete Group Files           |       |          |         | ✓          | ✓     |
| Create Project   |       |          |         | ✓          | ✓     |

(1) A user or bot account with the **Uploader** role can only perform these actions via the API.

(2) A user with the **Maintainer** role can only modify members up to and including their role.



## Project Level Permissions

| Action                               | Guest | Uploader | Analyst | Maintainer | Owner |
| :---------------------------------- | :---- | -------- | ------- | ---------- | ----- |
| View Project                        | ✓     | ✓(1)     | ✓       | ✓          | ✓     |
| Edit Project                        |       |          |         | ✓          | ✓     |
| Delete Project                      |       |          |         |            | ✓     |
| Transfer Project                    |       |          |         |            | ✓     |
| View Project Members                | ✓     |          | ✓       | ✓          | ✓     |
| Add Project Member                  |       |          |         | ✓(2)       | ✓     |
| Edit Project Member                 |       |          |         | ✓(2)       | ✓     |
| Remove Project Member               |       |          |         | ✓(2)       | ✓     |
| Add Bot Account                     |       |          |         | ✓          | ✓     |
| Remove Bot Account                  |       |          |         | ✓          | ✓     |
| Set up Automated Workflow Execution |       |          |         | ✓          | ✓     |
| View Automated Workflow Executions |       |          | ✓       | ✓          | ✓     |
| Launch User-launched Workflow Execution |       |          | ✓       | ✓          | ✓     |
| View User-launched Workflow Executions |       |          | ✓       | ✓          | ✓     |
| Add Metadata Template                |       |          |         | ✓          | ✓     |
| Update Metadata Template               |       |          |         | ✓          | ✓     |
| Delete Metadata Template                |       |          |         | ✓          | ✓     |
| Use Metadata Template               |       |          |         | ✓          | ✓     |
| View Project History                |       |          |         | ✓          | ✓     |
| View Project Files                  |       |          | ✓       | ✓          | ✓     |
| Download Project Files                  |       |          | ✓       | ✓          | ✓     |
| Upload Project Files                |       |          |         | ✓          | ✓     |
| Delete Project Files                |       |          |         | ✓          | ✓     |



(1) A user or bot account with the **Uploader** role can only perform these actions via the API.

(2) A user with the **Maintainer** role can only modify members up to and including their role.

## Sample Level Permissions

| Action                      | Guest | Uploader | Analyst | Maintainer | Owner |
| :--------------------------- | :---- | -------- | ------- | ---------- | ----- |
| View Samples          | ✓     | ✓(1)     | ✓       | ✓          | ✓     |
| Create Samples        |       | ✓(1)     |         | ✓          | ✓     |
| Edit Samples          |       | ✓(1)     |         | ✓          | ✓     |
| Delete Samples        |       |          |         |            | ✓     |
| Transfer Samples      |       |          |         | ✓(3)       | ✓     |
| Copy Samples         |       |          |         | ✓          | ✓     |
| Export Samples        |       |          | ✓       | ✓          | ✓     |
| View Sample History   |       |          |         | ✓          | ✓     |
| Upload Sample Files          |       |          |         | ✓          | ✓     |
| Concatenate Sample Files     |       |          |         | ✓          | ✓     |
| Download Sample Files        | ✓     |          | ✓       | ✓          | ✓     |
| Delete Sample Files          |       |          |         | ✓ (4)        | ✓     |
| View Metadata         | ✓     | ✓(1)     | ✓       | ✓          | ✓     |
| Add Metadata          |       |          |         | ✓          | ✓     |
| Update Metadata       |       |          |         | ✓          | ✓     |
| Import Metadata       |       |          |         | ✓          | ✓     |
| Delete Metadata       |       |          |         | ✓          | ✓     |

(1) A user or bot account with the **Uploader** role can only perform these actions via the API.

(2) A user with the **Maintainer** role can only modify members up to and including their role.

(3) A user with the **Maintainer** role can only transfer samples to another project under the common ancestor for the current project.

(4) A user with the **Maintainer** role can only delete files by selecting the “Delete Originals” checkbox when concatenating files.
