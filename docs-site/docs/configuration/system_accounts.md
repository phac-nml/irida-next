---
sidebar_position: 8
id: system_accounts
title: System Accounts
---

## Setup

To give a user `system` access, add the user(s) email address(es) to the credentials file. If a user's `system` access needs to be revoked, then remove the user's email address from the credentials file.

Edit your environment (development, production, etc) credentials file with the following command.

`EDITOR="vim --nofork" bin/rails credentials:edit --environment ENVIRONMENT`

[Read more about the rails credential file here](https://guides.rubyonrails.org/security.html#custom-credentials)

Follow the format below:

```yml
system_accounts:
  user_emails:
    - user1@email.com
    - user2@email.com
    - user3@email.com
    ...
```

## Functionality

`System` users have access to the following additional functionality in addition to their regular access to IRIDA Next:

- Query metrics through the GraphQL API (groups and projects)
