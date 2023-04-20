---
sidebar_position: 2
id: members
title: Members
---

In IRIDA Next, members are the users and groups which have access to your project. Each member has a role, which determines what they can do or access in the project.

## Membership Types

IRIDA Next has two types of membership

| Membership Type | Process                                            |
| :-------------- | :------------------------------------------------- |
| Direct          | The user is added directly to the group or project |
| Inherited       | The user is a member of an ancestor group          |

## Direct Membership

When the project belongs to a group, if a user is added directly to a project, and that user is a member of a parent group or it's ancestors, the minimum role that the user could be assigned in the project is their maximum role in the parent group and it's ancestors.

For Example:

- User 0 is a member of Group 1 with **Maintainer** role
- Group 1 has a subgroup Subgroup 1
- Project 1 belongs to Subgroup 1
- The only roles that User 0 can be assigned in the project are **Maintainer** and **Owner**

## Inherited Membership

When the project belongs to a group, the members of this project will inherit their role from the group and it's ancestors.

For Example:

- User 0 is a Member of Group 1 with a **Maintainer** role
- Group 1 has a subgroup Subgroup 1
- Project 1 belongs to Subgroup 1
- User 0 has the inherited membership in Project 1 through the ancestor (Group 1) of Subgroup 1 with the **Maintainer** role

## Membership and visibility rights

Depending on their membership type, members of groups or projects are granted different visibility levels and rights into the group or project.

| Action                      | Direct Member | Inherited Member |
| :-------------------------- | :------------ | ---------------- |
| Create/Edit/Delete Group    |               |
| Create/Edit/Delete Subgroup | &#x2713;      |                  |
| Create/Edit/Delete Project  |               |
| Add/Remove Members          |               |                  |

## Add members to a group

Add users to a group so they can have access to subgroups and projects within the group

Prerequisite:

You must have the **Owner** or **Maintainer** role, or you must be the owner of the group

To add a user to a group:

1. From the left sidebar, select **Groups**, and find your group
2. From the left sidebar, select **Members**
3. Click the **Add Member** button
4. Select the user you want to add to the group
5. Select an access level (role)
6. Click the **Add member to group** button

## Add members to a project

Add users to a project so they become direct members and have permission to perform actions.

Prerequisite:

You must have the **Owner** or **Maintainer** role, or the project must be under your user namespace.

To add a direct user to a project:

1. From the left sidebar, select **Projects**, and find your project
2. From the left sidebar, select **Members**
3. Click the **Add Member** button
4. Select the user you want to add to the project
5. Select an access level (role)
6. Click the **Add member to project** button

## Which roles you can assign

The maximum role you can assign depends on whether you have the **Owner** or **Maintainer** role for the group ancestory. For example, the maximum role you can set is:

- Owner (40), if you have the Owner role for the project.
- Maintainer (30), if you have the Maintainer role on the project.

## Remove a member from a project

If a user is:

- A direct member of a project, you can remove them directly from the project.
- An inherited member from a parent group, you can only remove them from the parent group itself.

Prerequisites:

- To remove direct members that have the:
  - Maintainer, Developer, Reporter, or Guest role, you must have the Maintainer role.
  - Owner role, you must have the Owner role.

To remove a member from a project:

1. From the left sidebar, select **Projects**, and find your project
2. From the left sidebar, select **Members**
3. On the right hand side of the row for the member you want to remove, click the `ellipsis` and select **Remove** from the dropdown.
4. Confirm that you would like to remove the member from the project in the popup by clicking the **OK** button

## Remove a member from a group

If a user is:

- A direct member of a group, you can remove them directly from the group.
- An inherited member from a parent group, you can only remove them from the parent group itself.

Prerequisites:

- To remove direct members that have the:
  - Maintainer, Developer, Reporter, or Guest role, you must have the Maintainer role.
  - Owner role, you must have the Owner role.

To remove a member from a group:

1. From the left sidebar, select **Projects**, and find your project
2. From the left sidebar, select **Members**
3. On the right hand side of the row for the member you want to remove, click the `ellipsis` and select **Remove** from the dropdown.
4. Confirm that you would like to remove the member from the project in the popup by clicking the **OK** button
