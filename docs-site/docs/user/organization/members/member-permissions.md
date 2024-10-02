---
sidebar_position: 2
id: member-permissions
title: Permissions and Roles
---

When you add a user to a project or group, you assign them a role. The role determines which actions they can take in IRIDA Next.

If you add a user to both a project’s group and the project itself, the higher role is used.

## Roles

The available roles are:

- Guest
- Uploader
- Analyst
- Maintainer
- Owner

A user assigned the Guest role has the least permissions, and the Owner has the most.

The **Uploader** is to be used for api access for the uploader

All users can create top-level groups and projects.

## Group Members Permissions

Any user can remove themselves from a group, unless they are the last Owner of the group.

The following table lists group permissions available for each role:

| Action                       | Guest | Uploader | Analyst | Maintainer | Owner |
| :--------------------------- | :---- | :------- | :------ | :--------- | :---- |
| Create Group and Subgroups   |       |          |         | ✓          | ✓     |
| Edit Group and Subgroups     |       |          |         | ✓          | ✓     |
| Delete Group and Subgroups   |       |          |         |            | ✓     |
| View Group and Subgroups     | ✓     | ✓ (2)    | ✓       | ✓          | ✓     |
| Transfer Group and Subgroups |       |          |         |            | ✓     |
| Add Group Member             |       |          |         | ✓(1)       | ✓     |
| Edit Group Member            |       |          |         | ✓(1)       | ✓     |
| Remove Group Member          |       |          |         | ✓(1)       | ✓     |
| View Group Members           | ✓     |          | ✓       | ✓          | ✓     |
| View Group Files             |       |          | ✓       | ✓          | ✓     |
| Upload Group Files           |       |          |         | ✓          | ✓     |
| Remove Group Files           |       |          |         | ✓          | ✓     |

1. A user with the **Maintainer** role can only modify members upto and including their role
2. A user or bot account with the **Uploader** role can only perform these actions via the api

## Subgroup permissions

When you add a member to a subgroup where they are also a member of one of the parent groups, they inherit the member role from the parent groups.

## Project Members Permissions

  - Project Management:

    | Action                              | Guest | Uploader | Analyst | Maintainer | Owner |
    | :---------------------------------- | :---- | -------- | ------- | ---------- | ----- |
    | View Project                        | ✓     | ✓(1)     | ✓       | ✓          | ✓     |
    | Create Project                      |       |          |         | ✓          | ✓     |
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
    | View Project History                |       |          |         | ✓          | ✓     |
    | View Project Files                  |       |          | ✓       | ✓          | ✓     |
    | Upload Project Files                |       |          |         | ✓          | ✓     |
    | Remove Project Files                |       |          |         | ✓          | ✓     |


  1. A user or bot account with the **Uploader** role can only perform these actions via the api
  2. A user with the **Maintainer** role can only modify members upto and including their role

  - Sample Management:

    | Action                | Guest | Uploader | Analyst | Maintainer | Owner |
    | :-------------------- | :---- | -------- | ------- | ---------- | ----- |
    | View Samples          | ✓     | ✓(1)     | ✓       | ✓          | ✓     |
    | Create Samples        |       | ✓(1)     |         | ✓          | ✓     |
    | Edit Samples          |       | ✓(1)     |         | ✓          | ✓     |
    | Delete Samples        |       |          |         |            | ✓     |
    | Transfer Samples      |       |          |         | ✓(2)       | ✓     |
    | Clone Samples         |       |          |         | ✓          | ✓     |
    | View Sample History   |       |          |         | ✓          | ✓     |

  1. A user or bot account with the **Uploader** role can only perform these actions via the api
  2. A user with the **Maintainer** role can only transfer samples to another project under the common ancestor for the current project

  - Sample File Management:

    | Action                | Guest | Uploader | Analyst | Maintainer | Owner |
    | :-------------------- | :---- | -------- | ------- | ---------- | ----- |
    | Upload Files          |       |          |         | ✓          | ✓     |
    | Concatenate Files     |       |          |         | ✓          | ✓     |
    | Download Files        | ✓     |          | ✓       | ✓          | ✓     |
    | Delete Files          |       |          |         |            | ✓     |

  - Sample Metadata Mangement:

    | Action                | Guest | Uploader | Analyst | Maintainer | Owner |
    | :-------------------- | :---- | -------- | ------- | ---------- | ----- |
    | Add Metadata          |       |          |         | ✓          | ✓     |
    | Update Metadata       |       |          |         | ✓          | ✓     |
    | Import Metadata       |       |          |         | ✓          | ✓     |
    | Delete Metadata       |       |          |         | ✓          | ✓     |
