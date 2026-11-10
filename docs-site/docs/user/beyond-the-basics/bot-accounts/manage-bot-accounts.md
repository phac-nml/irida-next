---
sidebar_position: 3
id: manage-bot-accounts
title: Manage Bot Accounts
---

## Manage Bot Accounts
The different bot account types are:
* **Group bot** - A bot that is created within a group. It can also be added as a member to other projects and groups.
* **Project bot** - A bot that is created within a project. This bot can only be associated with the project it was created in.
* **Project automation bot** - A bot that is automatically created when an automated workflow execution is generated. This bot is used to run automated workflow executions.


## Add a Bot Account

Prerequisite:

- **Maintainer** role (at minimum).

To add a bot account to a group or project:

1. From the left sidebar, select **Groups** or **Projects** and select the relevant group or project, respectively.
2. From the left sidebar, select **Settings > Bot Accounts**.
3. Click the **New bot account** button.
4.	In the pop-up window, you will see the following information: *This will create a bot user with email format 'inxt_grp_GROUP_PUID_bot_n@iridanext.com', add them as a member to the Group with 'Access level' role, and then create a personal access token for the bot using the details below.*
5.	Select an **Access Level** for the bot from the drop-down menu.
6.	Enter a name in the **Token Name** field.
7.	Set a **Token Expiration Date** (optional).
8.	Select **Scope**. Options include:
    * **api** – Grants complete read/write access to the API.
    * **read_api** – Grants read access to the API.
9.	Click the **Submit** button.
10.	You should now see the new bot account listed on the **Settings > Bot Accounts** page. Above the table you should also see a section for the newly created personal access token. **Copy the Personal Access Token, as it cannot be accessed afterwards. To use the GraphQL API with any of the GraphQL Clients, you will need a Personal Access Token.**


## Delete a Bot Account

Prerequisites:

- **Maintainer** role (at minimum).

To delete an existing bot account from a group or project:

1. From the left sidebar, select **Groups** or **Projects** and select the relevant group or project, respectively.
2. From the left sidebar, select **Settings > Bot Accounts**.
3. In the **Actions** column, select **Delete** in the row belonging to the relevant bot account.
4.	Confirm that you would like to permanently delete the bot account by clicking the **Confirm** button. All memberships associated with the deleted bot will automatically be removed.

## Add a Bot Member to a Group or Project

Prerequisite:

- **Maintainer** role (at minimum)

To add a bot member to a group or project:
1.	From the **Groups** or **Projects** page, select the relevant group or project.
2.	On the left side panel, select **Members**.
3.	Select the **Add New Member** button.
4. Under **User**, type or scroll to find the bot that would like to invite.
5. Under **Access Level**, select the appropriate access level/role.
6. Under **Access expiration**, select the date when you would like the group or project access to end (optional).
7.	Click **Add member to group** or **Add member to project**.

## Remove a Bot Member from a Group or Project

Prerequisites:

- **Maintainer** role (at minimum)

To remove a bot member from a group or project:

1. From the **Groups** or **Projects** page, select the relevant group or project.
2. From the left sidebar, select **Members**.
3. Find the bot member that you would like to remove.
4. To the right of the **Username**, under the **Action** column, click **Remove**.
5. Remove the member by clicking **Confirm** in the pop-up window.

If a bot member is:
* A direct member of a project, you can remove them directly from the project.
* An inherited member from a parent group, you can only remove them from the parent group itself.
