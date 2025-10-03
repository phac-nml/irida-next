---
sidebar_position: 2
id: member-permissions
title: Permissions et rôles
---

Lorsque vous ajoutez un utilisateur à un projet ou à un groupe, vous lui attribuez un rôle. Le rôle détermine quelles actions il peut effectuer dans IRIDA Next.

Si vous ajoutez un utilisateur à la fois au groupe d'un projet et au projet lui-même, le rôle le plus élevé est utilisé.

## Rôles

Les rôles disponibles sont :

- Invité
- Téléverseur
- Analyste
- Responsable
- Propriétaire

Un utilisateur affecté au rôle Invité a le moins de permissions, et le Propriétaire en a le plus.

Le **Téléverseur** doit être utilisé pour l'accès API pour le téléverseur

Tous les utilisateurs peuvent créer des groupes et des projets de niveau supérieur.

## Permissions des membres de groupe

Tout utilisateur peut se retirer d'un groupe, sauf s'il est le dernier Propriétaire du groupe.

Le tableau suivant liste les permissions de groupe disponibles pour chaque rôle :

| Action                                 | Invité | Téléverseur | Analyste | Responsable | Propriétaire |
| :------------------------------------- | :----- | :---------- | :------- | :---------- | :----------- |
| Créer des groupes et sous-groupes      |        |             |          | ✓           | ✓            |
| Modifier les groupes et sous-groupes   |        |             |          | ✓           | ✓            |
| Supprimer les groupes et sous-groupes  |        |             |          |             | ✓            |
| Voir les groupes et sous-groupes       | ✓      | ✓ (2)       | ✓        | ✓           | ✓            |
| Transférer les groupes et sous-groupes |        |             |          |             | ✓            |
| Ajouter un membre de groupe            |        |             |          | ✓(1)        | ✓            |
| Modifier un membre de groupe           |        |             |          | ✓(1)        | ✓            |
| Retirer un membre de groupe            |        |             |          | ✓(1)        | ✓            |
| Voir les membres de groupe             | ✓      |             | ✓        | ✓           | ✓            |
| Voir les fichiers de groupe            |        |             | ✓        | ✓           | ✓            |
| Téléverser des fichiers de groupe      |        |             |          | ✓           | ✓            |
| Retirer des fichiers de groupe         |        |             |          | ✓           | ✓            |

1. Un utilisateur avec le rôle **Responsable** ne peut modifier que les membres jusqu'à et y compris leur rôle
2. Un utilisateur ou un compte de robot avec le rôle **Téléverseur** ne peut effectuer ces actions que via l'API

## Permissions de sous-groupe

Lorsque vous ajoutez un membre à un sous-groupe où il est également membre de l'un des groupes parents, il hérite du rôle de membre des groupes parents.

## Permissions des membres de projet

- Gestion de projet :

  | Action                                                | Invité | Téléverseur | Analyste | Responsable | Propriétaire |
  | :---------------------------------------------------- | :----- | ----------- | -------- | ----------- | ------------ |
  | Voir le projet                                        | ✓      | ✓(1)        | ✓        | ✓           | ✓            |
  | Créer un projet                                       |        |             |          | ✓           | ✓            |
  | Modifier le projet                                    |        |             |          | ✓           | ✓            |
  | Supprimer le projet                                   |        |             |          |             | ✓            |
  | Transférer le projet                                  |        |             |          |             | ✓            |
  | Voir les membres du projet                            | ✓      |             | ✓        | ✓           | ✓            |
  | Ajouter un membre de projet                           |        |             |          | ✓(2)        | ✓            |
  | Modifier un membre de projet                          |        |             |          | ✓(2)        | ✓            |
  | Retirer un membre de projet                           |        |             |          | ✓(2)        | ✓            |
  | Ajouter un compte de robot                            |        |             |          | ✓           | ✓            |
  | Retirer un compte de robot                            |        |             |          | ✓           | ✓            |
  | Configurer l'exécution de flux de travail automatisée |        |             |          | ✓           | ✓            |
  | Voir l'historique du projet                           |        |             |          | ✓           | ✓            |
  | Voir les fichiers du projet                           |        |             | ✓        | ✓           | ✓            |
  | Téléverser des fichiers de projet                     |        |             |          | ✓           | ✓            |
  | Retirer des fichiers de projet                        |        |             |          | ✓           | ✓            |

1. Un utilisateur ou un compte de robot avec le rôle **Téléverseur** ne peut effectuer ces actions que via l'API
2. Un utilisateur avec le rôle **Responsable** ne peut modifier que les membres jusqu'à et y compris leur rôle

- Gestion des échantillons :

  | Action                             | Invité | Téléverseur | Analyste | Responsable | Propriétaire |
  | :--------------------------------- | :----- | ----------- | -------- | ----------- | ------------ |
  | Voir les échantillons              | ✓      | ✓(1)        | ✓        | ✓           | ✓            |
  | Créer des échantillons             |        | ✓(1)        |          | ✓           | ✓            |
  | Modifier les échantillons          |        | ✓(1)        |          | ✓           | ✓            |
  | Supprimer les échantillons         |        |             |          |             | ✓            |
  | Transférer les échantillons        |        |             |          | ✓(2)        | ✓            |
  | Cloner les échantillons            |        |             |          | ✓           | ✓            |
  | Exporter les échantillons          |        |             | ✓        | ✓           | ✓            |
  | Voir l'historique de l'échantillon |        |             |          | ✓           | ✓            |

1. Un utilisateur ou un compte de robot avec le rôle **Téléverseur** ne peut effectuer ces actions que via l'API
2. Un utilisateur avec le rôle **Responsable** ne peut transférer des échantillons que vers un autre projet sous l'ancêtre commun pour le projet actuel

- Gestion des fichiers d'échantillon :

  | Action                   | Invité | Téléverseur | Analyste | Responsable | Propriétaire |
  | :----------------------- | :----- | ----------- | -------- | ----------- | ------------ |
  | Téléverser des fichiers  |        |             |          | ✓           | ✓            |
  | Concaténer des fichiers  |        |             |          | ✓           | ✓            |
  | Télécharger des fichiers | ✓      |             | ✓        | ✓           | ✓            |
  | Supprimer des fichiers   |        |             |          |             | ✓            |

- Gestion des métadonnées d'échantillon :

  | Action                        | Invité | Téléverseur | Analyste | Responsable | Propriétaire |
  | :---------------------------- | :----- | ----------- | -------- | ----------- | ------------ |
  | Ajouter des métadonnées       |        |             |          | ✓           | ✓            |
  | Mettre à jour les métadonnées |        |             |          | ✓           | ✓            |
  | Importer des métadonnées      |        |             |          | ✓           | ✓            |
  | Supprimer des métadonnées     |        |             |          | ✓           | ✓            |
