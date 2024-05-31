---
sidebar_position: 4
id: manage-bot-PAT
title: Manage Bot Account Personal Access Tokens
---

Personal Access Tokens (PAT) are needed to use the IRIDA Next GraphQL API. See [Authentication with Personal Access Tokens](/docs/extend/graphql#authentication-with-personal-access-tokens) for more information.

## View PAT

Prerequisite:

- You must have at least a **Maintainer** role.

To view a bot account PAT within a group:

1. From the left sidebar, select **Groups** and find your group.
2. From the left sidebar, select **Settings > Bot Accounts**.
3. Click on the **Active Tokens** total link within the row of the bot account PAT you want to view. A list of the active personal access tokens will be displayed.

## Generate PAT

Prerequisite:

- You must have at least a **Maintainer** role.

To generate a bot account PAT within a group:

1. From the left sidebar, select **Groups** and find your group.
2. From the left sidebar, select **Settings > Bot Accounts**.
3. On the right hand side of the row for the bot account, click the **Generate new token** link.
4. Enter the token name in the **Name** field.
5. Select an access level.
6. Set an optional expiry date.
7. Select at least one scope.
8. Click the **Submit** button.

## Revoke PAT

Prerequisite:

- You must have at least a **Maintainer** role.

To revoke a bot account PAT within a group:

1. From the left sidebar, select **Groups** and find your group.
2. From the left sidebar, select **Settings > Bot Accounts**.
3. Click on the **Active Tokens** total link within the row of the bot account PAT you want to revoke. A list of the active personal access tokens will be displayed.
4. On the right hand side of the row for the bot account PAT, click the **Revoke** button.
5. Confirm that you would like to revoke the bot account PAT by clicking the **Confirm** button.
