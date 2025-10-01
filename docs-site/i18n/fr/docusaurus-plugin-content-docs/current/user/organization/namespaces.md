---
sidebar_position: 1
id: namespaces
title: Espaces de noms
---

Dans IRIDA Next, un _espace de noms_ fournit un endroit pour organiser vos projets connexes. Les projets dans un espace de noms sont séparés des projets dans d'autres espaces de noms, ce qui signifie que vous pouvez utiliser le même nom pour des projets dans différents espaces de noms.

## Types d'espaces de noms

IRIDA Next a deux types d'espaces de noms :

- Un espace de noms _personnel_, qui est basé sur votre adresse courriel et vous est fourni lorsque vous créez votre compte.
  - Vous ne pouvez pas créer de sous-groupes dans un espace de noms personnel.
  - Les groupes dans votre espace de noms n'héritent pas de vos permissions d'espace de noms et des fonctionnalités de groupe.
  - Tous les projets que vous créez sont sous la portée de cet espace de noms.
  - Si vous changez votre adresse courriel, les URL du projet et de l'espace de noms dans votre compte changent également.
- Un espace de noms de _groupe_ ou de _sous-groupe_, qui est basé sur le nom du groupe ou du sous-groupe :
  - Vous pouvez créer plusieurs sous-groupes pour gérer plusieurs projets.
  - Vous pouvez configurer des paramètres spécifiquement pour chaque sous-groupe et projet dans l'espace de noms.
  - Vous pouvez modifier l'URL des espaces de noms de groupe et de sous-groupe.

## Déterminer quel type d'espace de noms vous consultez

Pour déterminer si vous consultez un espace de noms de groupe ou personnel, vous pouvez consulter l'URL. Par exemple :

| Espace de noms pour                                           | Url                                                      | Espace de noms            |
| :------------------------------------------------------------ | :------------------------------------------------------- | :------------------------ |
| Un utilisateur avec l'adresse courriel `john.doe@example.com` | `https://irida-next.example.com/john.doe_at_example.com` | `john.doe_at_example.com` |
| Un groupe nommé `pathogen`                                    | `https://irida-next.example.com/pathogen`                | `pathogen`                |
| Un groupe nommé `pathogen` avec un sous-groupe nommé `surveillance` | `https://irida-next.example.com/pathogen/surveillance`   | `pathogen/surveillance`   |

## Limitations de nommage pour les espaces de noms

Lors du choix d'un nom pour votre espace de noms, gardez à l'esprit les [limitations de caractères](../project/projects/reserved-names#limitations-on-project-names), les [noms de groupe réservés](../organization/groups/reserved-names) et les [noms de projet réservés](../project/projects/reserved-names#reserved-project-names).
