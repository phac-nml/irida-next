---
sidebar_position: 1
id: reserved-names
title: Reserved project names
---

Not all project names are allowed because they would conflict with existing routes used by IRIDA Next.

For a list of words that are not allowed to be used as project names, see the `path_regex.rb` file under the `TOP_LEVEL_ROUTES`, and `WILDCARD_ROUTES` lists:
* `TOP_LEVEL_ROUTES`: are names that are reserved as usernames or top level groups.
* `WILDCARD_ROUTES`: are names that are reserved for child groups or projects.

## Limitations on project names

* Project names must start with a letter, digit, emoji, or "_".
* Project names can only contain letters, digits, emojis, "_", ".", dashes, or spaces.
* Project slugs must start with a letter or digit.
* Project slugs can only contain letters, digits, ‘_’, ‘.’, ‘+’, or dashes.
* Project slugs must not contain consecutive special characters.
* Project slugs cannot end with a special character.

## Reserved project names

It is not possible to create a project with the following names:
* `\-`
