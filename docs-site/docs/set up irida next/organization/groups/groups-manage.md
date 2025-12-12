---
id: manage
sidebar_position: 2
---

# Manage Groups



## View Groups

Selecting **Groups** on the sidebar will bring you to the **Groups** page.

The **Groups** page provides a list of all groups that you have created or that have been shared with you. You will only see groups that you are a member of.  Your membership in a parent group gives you access to all of its subgroups and projects.

The list includes information about the groups, including:
* Group Name

* Group ID

* Your group role (Owner, Maintainer, etc.)

* Icons indicating the number of subgroups, projects, and samples within the group


The search bar allows you to filter the list of groups by ID or group name.  You can also sort your list of groups by date of update, date of creation, and name.

To select a group, to view:
1. Click on the **Group Name**. The group will open to the **Details** page where you can find a list of all subgroups and projects within the group. New subgroups and projects can also be created using buttons on this page.

The left panel menu within a group contains links to the Details page, Samples, Files, Members, Activity, Workflow Executions, and Settings.


## Create a Group

To create a group, either:

1. Select the “+” button on the sidebar. Choose **Create new group**. Or,

2. From the **Your work menu**, select the **Groups** page. Select the **New group** button.

Both options will bring you to the **Create group** page.

On the Create group page:

* Enter a name for the group in the **Group name** field. It must be at least 3 letters long and start with a letter, digit, or emoji. Please see [IRIDA Next Naming Restrictions](../../project/projects/reserved-names) for more information.

* The **Path** field will auto populate to match your Group name. This can be edited but characters are limited to letters, numbers, dashes and underscores as the path is used in URLs.

* The **Description** field is optional. This description will show up under your group name on the groups page.

**Note:** Not all group names are allowed because they would conflict with existing routes used by IRIDA Next.

Of note, you will not be able to create a “parent” group using a name that has already been used on another “parent” group in IRIDA Next. However, subgroups can have the same name as other subgroups as long as they don’t exist within the same parent group.

For example: If Bob makes a parent group called “Pathogens”, Cheryl cannot make a parent group called “Pathogens”. So, Cheryl calls her parent group “Pathogens1”. Bob has a subgroup called “Bacteria” within his “Pathogens” group. Cheryl is able to make a subgroup called “Bacteria” within her “Pathogens1” group as well.

## Delete a Group
Deleting a group is permanent and cannot be undone. All projects, subgroups, automated workflow results, samples, files and direct members will be deleted along with the group. You must have Owner permissions to delete a group.

To delete a group:

1. In the **Groups** page, select the group that you would like to delete by clicking on the group name.

2. On the left sidebar, select **Settings** > **General**.

3. Under Delete group, select the **Delete group** button.

4. In the pop-up, confirm your intention by typing the group name.

5. Select the **Confirm** button.

## Edit Group Details

Prerequisite:

* **Maintainer** role in the Group (at minimum).

To edit the group details:

1. Select the group that you want to edit and then on the left sidebar, select **Settings** > **General**.

2. To update the **Name** or **Description**:
    * In the **Group name** field, enter the name of the project. Please see [IRIDA Next Naming Restrictions](../../project/projects/reserved-names) for more information.

   * In the **Description** field, enter a description. This field is optional.

3. Select **Save changes**.
