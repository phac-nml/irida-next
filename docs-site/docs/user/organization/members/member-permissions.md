---
sidebar_position: 3
id: membersship-permissions
title: Permissions and Roles
---

When you add a user to a project or group, you assign them a role. The role determines which actions they can take in IRIDA Next.

If you add a user to both a project’s group and the project itself, the higher role is used.

## Roles

The available roles are:

- Guest
- Analyst
- Maintainer
- Owner

A user assigned the Guest role has the least permissions, and the Owner has the most.

All users can create top-level groups and projects.

## Group Members Permissions

Any user can remove themselves from a group, unless they are the last Owner of the group.

The following table lists group permissions available for each role:

| Action              | Guest | Analyst | Maintainer | Owner |
| :------------------ | :---- | :------ | :--------- | :---- |
| Create Group        |       |         | ✓          | ✓     |
| Edit Group          |       |         | ✓          | ✓     |
| Delete Group        |       |         |            | ✓     |
| Create SubGroup     |       |         | ✓          | ✓     |
| Edit SubGroup       |       |         | ✓          | ✓     |
| Delete SubGroup     |       |         |            | ✓     |
| Add Group Member    |       |         | ✓          | ✓     |
| Edit Group Member   |       |         | ✓          | ✓     |
| Remove Group Member |       |         | ✓          | ✓     |

## Subgroup permissions

When you add a member to a subgroup where they are also a member of one of the parent groups, they inherit the member role from the parent groups.

## Project Members Permissions

| Action                | Guest | Analyst | Maintainer | Owner |
| :-------------------- | :---- | ------- | ---------- | ----- |
| Create Project        |       |         | ✓          | ✓     |
| Edit Project          |       |         | ✓          | ✓     |
| Delete Project        |       |         |            | ✓     |
| Create Project        |       |         | ✓          | ✓     |
| Edit Project          |       |         | ✓          | ✓     |
| Delete Project        |       |         |            | ✓     |
| Add Project Member    |       |         | ✓          | ✓     |
| Edit Project Member   |       |         | ✓          | ✓     |
| Remove Project Member |       |         | ✓          | ✓     |
