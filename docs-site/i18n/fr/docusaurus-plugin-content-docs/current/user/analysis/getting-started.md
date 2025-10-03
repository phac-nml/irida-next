---
sidebar_position: 1
id: getting-started
title: Mise en route
---

Dans IRIDA Next, l'analyse des échantillons est effectuée à l'aide de pipelines d'exécution de flux de travail.

## Types d'exécution de flux de travail

Il existe deux types d'exécutions de flux de travail dans IRIDA Next :

| Type d'exécution de flux de travail | Description                                                                                                                     |
| :----------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| Utilisateur                          | Permet aux utilisateurs de sélectionner un nombre quelconque d'échantillons appartenant à un groupe ou à un projet et d'effectuer une analyse sur ceux-ci. |
| Automatisée                          | Les exécutions de flux de travail automatisées appartiennent aux projets et, une fois configurées, une analyse est effectuée sur tous les fichiers appariés nouvellement téléversés dans ce projet. |

Les exécutions de flux de travail utilisateur sont personnelles et ne sont accessibles qu'à l'utilisateur qui les a créées, tandis que les exécutions de flux de travail automatisées sont accessibles à tous les membres du projet qui ont au moins le rôle d'analyste.

## Exigences

Vous aurez besoin des éléments suivants pour effectuer des exécutions de flux de travail :
  - Exécution de flux de travail utilisateur
    - Un projet qui possède au moins un échantillon associé, et des fichiers appariés téléversés vers l'échantillon.
    - Au moins le rôle d'analyste pour le projet contenant les échantillons pour l'exécution du flux de travail.
  - Exécution de flux de travail automatisée
    - Un projet et au moins le rôle de mainteneur pour ce projet.

## États d'exécution de flux de travail

Pendant qu'une exécution de flux de travail est en cours, elle passera par de nombreux états pour vous informer de sa progression.

  États pour une exécution de flux de travail réussie (dans l'ordre) :

  | État       | Description                                                                                                                 |
  | :--------- | :-------------------------------------------------------------------------------------------------------------------------- |
  | Nouveau    | Il s'agit de l'état initial confirmant que l'exécution du flux de travail a été créée avec succès et prépare ses fichiers pour l'analyse |
  | Préparé    | Les fichiers ont été préparés avec succès et sont en cours de soumission au pipeline sélectionné                            |
  | Soumis     | L'exécution du flux de travail a été soumise au pipeline sélectionné                                                        |
  | En cours   | L'exécution du flux de travail est en cours d'exécution par le pipeline sélectionné                                         |
  | Finalisation | L'analyse a réussi et IRIDA Next finalise l'exécution du flux de travail pour l'utilisateur                                |
  | Terminé    | L'exécution du flux de travail est terminée et prête pour l'utilisateur                                                     |

  États d'erreur :

  | État           | Description                                                                                |
  | :------------- | :----------------------------------------------------------------------------------------- |
  | Erreur         | Une erreur s'est produite pendant l'analyse et l'exécution a été interrompue               |
  | Annulation     | L'exécution du flux de travail a été annulée et IRIDA Next est en train d'annuler l'exécution |
  | Annulé         | L'exécution du flux de travail a été annulée avec succès                                   |

L'état actuel de toute exécution de flux de travail est affiché sur la [page de liste](../analysis/working-with-workflow-executions) des exécutions de flux de travail.

## Suppressions d'exécution de flux de travail

Lors de la suppression d'une exécution de flux de travail, il y a quelques points à garder à l'esprit :
  - Les exécutions supprimées ayant échoué ou annulées n'ont pas de considérations supplémentaires
  - La suppression d'exécutions terminées ne supprime pas les résultats associés qui ont été propagés aux échantillons
