---
sidebar_position: 2
id: working-with-exports
title: Travailler avec les exportations
---

## Voir les exportations

Il existe deux façons de naviguer et de voir vos exportations :

* Si vous consultez actuellement un projet ou un groupe, cliquez sur le menu déroulant dans la barre latérale gauche qui contient le nom du projet ou du groupe, puis cliquez sur **Exportations de données** dans le menu déroulant.
* Si vous ne consultez pas actuellement un projet ou un groupe, cliquez sur **Exportations de données** dans la barre latérale gauche.

La page des exportations répertorie toutes vos exportations actuelles.

## Voir une seule exportation

Pour voir une seule exportation :
  1. Suivez les [étapes](../export/working-with-exports#view-exports) pour naviguer vers la page des exportations.
  2. Cliquez sur l'**ID** ou le **nom** de l'exportation souhaitée.

Chaque exportation individuelle contiendra un onglet de résumé. Les exportations d'échantillon et d'analyse auront également un onglet d'aperçu disponible. L'onglet d'aperçu contient un aperçu du contenu de l'exportation et n'est disponible qu'une fois que le statut de l'exportation est **Prêt**.

## Créer une exportation d'échantillon

Prérequis :
  * Un projet doit contenir au moins un échantillon, et cet échantillon doit avoir des fichiers téléversés.
  * Vous devez avoir au moins le rôle Analyste pour le projet et/ou le groupe à partir duquel vous créerez l'exportation.

Pour créer une exportation d'échantillon :
1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) ou le [groupe](../organization/groups/manage#view-groups) qui contient les échantillons que vous souhaitez exporter.
2. Dans la barre latérale gauche, sélectionnez **Échantillons**.
3. Cochez la case de chaque échantillon que vous souhaitez exporter.
4. Cliquez sur **Créer une exportation**.
5. Dans le menu déroulant, sélectionnez **Exportation d'échantillon**.
6. Une fenêtre contextuelle apparaîtra demandant les informations suivantes :
   - Les formats de fichiers que vous souhaitez inclure dans l'exportation. Cela vous permet de filtrer tous les formats de fichiers que vous ne souhaitez pas exporter. Vous devez inclure au moins un format de fichier pour créer une exportation.
   - Si vous souhaitez donner un nom à l'exportation (non requis).
   - Si vous souhaitez recevoir une notification par courriel lorsque l'exportation est prête à être téléchargée (non requis).

## Créer une exportation de liste linéaire

Prérequis :
  * Un projet doit contenir au moins un échantillon, et cet échantillon doit contenir des métadonnées.
  * Vous devez avoir au moins le rôle Analyste pour le projet et/ou le groupe à partir duquel vous créerez l'exportation.

Pour créer une exportation de liste linéaire d'échantillons :
1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) ou le [groupe](../organization/groups/manage#view-groups) qui contient les échantillons que vous souhaitez exporter.
2. Dans la barre latérale gauche, sélectionnez **Échantillons**.
3. Cochez la case de chaque échantillon que vous souhaitez exporter.
4. Cliquez sur **Créer une exportation**.
5. Dans le menu déroulant, sélectionnez **Exportation de liste linéaire**.
6. Une fenêtre contextuelle apparaîtra demandant les informations suivantes :
   - Les champs de métadonnées que vous souhaitez inclure dans l'exportation. Cela vous permet de filtrer tous les champs de métadonnées que vous ne souhaitez pas exporter. Vous devez inclure au moins un champ de métadonnées pour créer une exportation.
   - Le format de fichier de l'exportation.
   - Si vous souhaitez donner un nom à l'exportation (non requis).
   - Si vous souhaitez recevoir une notification par courriel lorsque l'exportation est prête à être téléchargée (non requis).

## Créer une exportation d'analyse à partir d'une exécution de flux de travail utilisateur

Prérequis :
  * Une exécution de flux de travail avec l'état terminé.

Pour créer une exportation d'analyse à partir d'une exécution de flux de travail utilisateur :
  1. [Naviguez](../analysis/working-with-workflow-executions#view-user-workflow-executions) vers la page des exécutions de flux de travail.
  2. Cliquez sur l'exécution de flux de travail que vous souhaitez exporter.
  3. Cliquez sur **Créer une exportation**.
  4. Une fenêtre contextuelle apparaîtra demandant si vous souhaitez donner un nom à l'exportation et si vous souhaitez recevoir une notification par courriel lorsque l'exportation est prête à être téléchargée. Aucun de ces éléments n'est requis pour créer l'exportation.

## Créer une exportation d'analyse à partir d'une exécution de flux de travail automatisée

Prérequis :
  * Projet ayant au moins une exécution de flux de travail automatisée avec un état terminé.
  * Vous devez avoir au moins le rôle Analyste pour le projet contenant l'exécution de flux de travail automatisée.

Pour créer une exportation d'analyse à partir d'une exécution de flux de travail automatisée :
  1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) contenant l'exécution de flux de travail.
  2. Dans la barre latérale gauche, cliquez sur **Exécutions de flux de travail**.
  3. Cliquez sur l'exécution de flux de travail que vous souhaitez exporter.
  4. Cliquez sur **Créer une exportation**.
  5. Une fenêtre contextuelle apparaîtra demandant si vous souhaitez donner un nom à l'exportation et si vous souhaitez recevoir une notification par courriel lorsque l'exportation est prête à être téléchargée. Aucun de ces éléments n'est requis pour créer l'exportation.

## Télécharger une exportation

Prérequis :
  * L'exportation a un statut **Prêt**.

Pour télécharger une exportation, soit :
  * Naviguez vers la page de liste des exportations et cliquez sur le lien **Télécharger** de l'exportation que vous souhaitez télécharger.
  * Naviguez vers la page de l'exportation et cliquez sur le bouton **Télécharger**.

## Supprimer une exportation

Pour supprimer une exportation, soit :
  * Naviguez vers la page de liste des exportations et cliquez sur le lien **Supprimer** de l'exportation que vous souhaitez supprimer.
  * Naviguez vers la page de l'exportation et cliquez sur le bouton **Retirer**.
