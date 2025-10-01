---
sidebar_position: 1
id: reserved-names
title: Noms de groupe réservés
---

Tous les noms de groupe ne sont pas autorisés car ils entreraient en conflit avec les routes existantes utilisées par IRIDA Next.

Pour une liste de mots qui ne sont pas autorisés à être utilisés comme noms de groupe, consultez le fichier `path_regex.rb` sous les listes `TOP_LEVEL_ROUTES` et `WILDCARD_ROUTES` :
* `TOP_LEVEL_ROUTES` : sont des noms qui sont réservés comme noms d'utilisateur ou groupes de niveau supérieur.
* `WILDCARD_ROUTES` : sont des noms qui sont réservés pour les groupes enfants ou les projets.

## Limitations sur les noms de groupe

* Les noms de groupe doivent commencer par une lettre, un chiffre, un emoji ou "_".
* Les noms de groupe ne peuvent contenir que des lettres, des chiffres, des emojis, "_", ".", des tirets ou des espaces.
* Les slugs de groupe doivent commencer par une lettre ou un chiffre.
* Les slugs de groupe ne peuvent contenir que des lettres, des chiffres, '_', '.', '+' ou des tirets.
* Les slugs de groupe ne doivent pas contenir de caractères spéciaux consécutifs.
* Les slugs de groupe ne peuvent pas se terminer par un caractère spécial.

## Noms de groupe réservés

Les noms suivants sont réservés comme groupes de niveau supérieur :
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

Ces noms de groupe ne sont pas disponibles comme noms de sous-groupe :
* `\-`
