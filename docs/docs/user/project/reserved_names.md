---
sidebar_position: 1
id: reserved_names
title: Reserved project and group names
---

Not all project & group names are allowed because they would conflict with existing routes used by IRIDA Next.

For a list of words that are not allowed to be used as group or project names, see the `path_regex.rb` file under the `TOP_LEVEL_ROUTES`, and `WILDCARD_ROUTES` lists:
* `TOP_LEVEL_ROUTES`: are names that are reserved as usernames or top level groups.
* `WILDCARD_ROUTES`: are names that are reserved for child groups or projects.

## Limitations on project and group names

* Project or group names must start with a letter, digit, emoji, or "_".
* Project or group names can only contain letters, digits, emojis, "_", ".", dashes, or spaces.
* Project or group slugs must start with a letter or digit.
* Project or group slugs can only contain letters, digits, ‘_’, ‘.’, ‘+’, or dashes.
* Project or group slugs must not contain consecutive special characters.
* Project or group slugs cannot end with a special character.

## Reserved project names

It is not possible to create a project with the following names:
* `\-`

## Reserved group names

The following names are reserved as top level groups:
* '\-'
* 404.html
* 422.html
* 500.html
* apple-touch-icon-precomposed.png
* apple-touch-icon.png
* assets
* favicon.ico
* groups
* rails
* recede_historical_location
* resume_historical_location
* refresh_historical_location
* robots.txt
* user

These group names are unavailable as subgroup names:
* '\-'
