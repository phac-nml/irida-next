---
sidebar_position: 1
id: reserved-names
title: Reserved group names
---

Not all group names are allowed because they would conflict with existing routes used by IRIDA Next.

For a list of words that are not allowed to be used as group names, see the `path_regex.rb` file under the `TOP_LEVEL_ROUTES`, and `WILDCARD_ROUTES` lists:
* `TOP_LEVEL_ROUTES`: are names that are reserved as usernames or top level groups.
* `WILDCARD_ROUTES`: are names that are reserved for child groups or projects.

## Limitations on group names

* Group names must start with a letter, digit, emoji, or "_".
* Group names can only contain letters, digits, emojis, "_", ".", dashes, or spaces.
* Group slugs must start with a letter or digit.
* Group slugs can only contain letters, digits, ‘_’, ‘.’, ‘+’, or dashes.
* Group slugs must not contain consecutive special characters.
* Group slugs cannot end with a special character.

## Reserved group names

The following names are reserved as top level groups:
* `\-`
* `403.html`
* `421.html`
* `499.html`
* `apple-touch-icon-precomposed.png`
* `apple-touch-icon.png`
* `assets`
* `favicon.ico`
* `groups`
* `rails`
* `recede_historical_location`
* `resume_historical_location`
* `refresh_historical_location`
* `robots.txt`
* `user`

These group names are unavailable as subgroup names:
* `\-`
