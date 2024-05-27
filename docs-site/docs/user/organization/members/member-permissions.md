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
| View Group and Subgroups     | ✓     |          | ✓       | ✓          | ✓     |
| Transfer Group and Subgroups |       |          |         |            | ✓     |
| Add Group Member             |       |          |         | ✓(1)       | ✓     |
| Edit Group Member            |       |          |         | ✓(1)       | ✓     |
| Remove Group Member          |       |          |         | ✓(1)       | ✓     |
| View Group Members           | ✓     |          | ✓       | ✓          | ✓     |
<!-- TODO: Add uploader actions -->
1. A user with the **Maintainer** role can only modify members upto and including their role

## Subgroup permissions

When you add a member to a subgroup where they are also a member of one of the parent groups, they inherit the member role from the parent groups.

## Project Members Permissions

| Action                | Guest | Analyst | Maintainer | Owner |
| :-------------------- | :---- | ------- | ---------- | ----- |
| Create Project        |       |         | ✓          | ✓     |
| Edit Project          |       |         | ✓          | ✓     |
| Delete Project        |       |         |            | ✓     |
| View Project          | ✓     | ✓       | ✓          | ✓     |
| Transfer Project      |       |         |            | ✓     |
| Add Project Member    |       |         | ✓(1)       | ✓     |
| Edit Project Member   |       |         | ✓(1)       | ✓     |
| Remove Project Member |       |         | ✓(1)       | ✓     |
| View Project Members  | ✓     | ✓       | ✓          | ✓     |
| Create Samples        |       |         | ✓          | ✓     |
| Edit Samples          |       |         | ✓          | ✓     |
| Delete Samples        |       |         |            | ✓     |
| Transfer Samples      |       |         | ✓(2)       | ✓     |
<!-- TODO: Add metadata, files, history, bot account permissions to project members permissions table -->
1. A user with the **Maintainer** role can only modify members upto and including their role
2. A user with the **Maintainer** role can only transfer samples to another project under the common ancestor for the current project
