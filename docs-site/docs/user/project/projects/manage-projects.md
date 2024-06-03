---
sidebar_position: 2
id: manage-projects
title: Manage Projects
---

Most of the work done in IRIDA next is done in a project.

## View projects you have access to

To view personal projects, projects that you are a member of, or provided access via sharing with a group that you are a member of:

1. On the left sidebar select **Projects**. This will list all the projects that you have access to
2. To view your personal projects, select the **Personal** tab

In IRIDA Next, you can create a project in a few different ways

## Create a project under user namespace

To create a project under your user namespace:

1. On the left sidebar, at the top, select (**+**) and **Create new project**, or if on the **Projects** view select **New project**
2. Enter the project details:
   - In the **Project name** field, enter the name of the project. [See the limitations for project names.](reserved-names)
   - The **Project URL** is automatically set to your user namespace. You may change it if you would like the project to be under a different namespace. Note that projects can only live under a **user** or **group namespace**.
   - In the **Path** field, enter the path to your project. To change the path first enter the project name, then change the path.
   - In the **Description** field, enter a description. This field is optional.
3. Select **Create project**

## Create a project under group

To create a project under group namespace:

Prerequisite:

- You must have at least the Maintainer role for the group if creating a project under a group

1. From within a group, select **New project**
2. Enter the project details:
   - In the **Project name** field, enter the name of the project. [See the limitations for project names.](reserved-names)
   - The **Project URL** is automatically set to the current group namespace. You may change it if you would like the project to be under a different namespace. Note that projects can only live under a **user** or **group namespace**.
   - In the **Path** field, enter the path to your project. To change the path first enter the project name, then change the path.
   - In the **Description** field, enter a description. This field is optional.
3. Select **Create project**

## Edit Project Details

Prerequisite:

- You must have at least the Maintainer role for the project.

To edit the project details:

1. Select the project that you want to edit and then on the left sidebar, select **Settings**
2. To update the **Name** or **Description**:

   - In the **Project name** field, enter the name of the project. [See the limitations for project names.](reserved-names)
   - In the **Description** field, enter a description. This field is optional.

3. Select **Update project**

## Edit Project URL

Prerequisite:

- You must have at least the Maintainer role for the project.

To update the URL of the project:

1. Select the project that you want to edit and then on the left sidebar, select **Settings**
2. In the **Advanced settings** section:

   - Enter the new URL for the project. Note that this could have unintended side effects.

3. Select **Change project URL**

## View Project History

Prerequisite:
- You must have at least the Maintainer role for the project.

To view a project's history:

1. Select the project that you want to edit and then on the left sidebar
2. Select **History**

A new project version is created each time the project's information is changed. Clicking a version within the project's history will display what changes were made to the project.

## Transfer Project

Prerequisites:

- You must have at least the Maintainer role for the group you are transferring to.
- You must have at least the Owner role for the project you transfer.

To transfer the project into another namespace:

1. Select the project that you want to edit and then on the left sidebar, select **Settings**
2. In the **Advanced settings** -> **Transfer project** section:
   - Select the new namespace that you would like the project to be under. Note that you can transfer the project into any namespace that you have direct access to or through sharing.
   - Select **Transfer project**
   - In the pop-ip, type in the name of the project and select **Confirm**

## Delete Project

Prerequisite:

- You must have at least the Owner role for the project.

1. Select the project that you want to edit and then on the left sidebar, select **Settings**
2. In the **Advanced settings** -> **Delete project** section:
   - Select **Delete project**
   - In the pop-up, select **Confirm**
