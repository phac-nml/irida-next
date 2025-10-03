---
sidebar_position: 1
id: reserved-names
title: Noms de projet réservés
---

Tous les noms de projet ne sont pas autorisés car ils entreraient en conflit avec les routes existantes utilisées par IRIDA Next.

Pour une liste de mots qui ne sont pas autorisés à être utilisés comme noms de projet, consultez le fichier `path_regex.rb` sous les listes `TOP_LEVEL_ROUTES` et `WILDCARD_ROUTES` :
* `TOP_LEVEL_ROUTES` : sont des noms qui sont réservés comme noms d'utilisateur ou groupes de niveau supérieur.
* `WILDCARD_ROUTES` : sont des noms qui sont réservés pour les groupes enfants ou les projets.

## Limitations sur les noms de projet

* Les noms de projet doivent commencer par une lettre, un chiffre, un emoji ou "_".
* Les noms de projet ne peuvent contenir que des lettres, des chiffres, des emojis, "_", ".", des tirets ou des espaces.
* Les slugs de projet doivent commencer par une lettre ou un chiffre.
* Les slugs de projet ne peuvent contenir que des lettres, des chiffres, '_', '.', '+' ou des tirets.
* Les slugs de projet ne doivent pas contenir de caractères spéciaux consécutifs.
* Les slugs de projet ne peuvent pas se terminer par un caractère spécial.

## Noms de projet réservés

Il n'est pas possible de créer un projet avec les noms suivants :
* `\-`
