---
sidebar_position: 2
id: working-with-workflow-executions
title: Travailler avec les exécutions de flux de travail
---

Apprenez à utiliser les exécutions de flux de travail dans IRIDA Next

## Voir les exécutions de flux de travail utilisateur

Il existe deux façons de naviguer et de voir vos exécutions de flux de travail utilisateur :

- Si vous consultez actuellement un projet ou un groupe, cliquez sur le menu déroulant dans la barre latérale gauche qui contient le nom du projet ou du groupe, puis cliquez sur **Exécutions de flux de travail** dans le menu déroulant.
- Si vous ne consultez pas actuellement un projet ou un groupe, cliquez sur **Exécutions de flux de travail** dans la barre latérale gauche.

Cette page répertorie toutes vos exécutions de flux de travail.

## Voir les exécutions de flux de travail automatisées

Prérequis :

- Vous devez avoir au moins le rôle Analyste pour le projet contenant les exécutions de flux de travail.

Pour voir les exécutions de flux de travail automatisées :

1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) contenant les exécutions de flux de travail
2. Cliquez sur **Exécutions de flux de travail**

Cette page répertorie toutes les exécutions de flux de travail du projet.

## Voir une exécution de flux de travail

Pour voir une exécution de flux de travail spécifique :

1. Suivez les étapes pour voir la page de liste des exécutions de flux de travail [utilisateur](../analysis/working-with-workflow-executions#view-user-workflow-executions) ou [automatisées](../analysis/working-with-workflow-executions#view-automated-workflow-executions)
2. Cliquez sur l'**ID** de l'exécution de flux de travail que vous souhaitez voir

Chaque exécution de flux de travail individuelle contiendra un résumé, les paramètres sélectionnés lors de la configuration, une feuille d'échantillons qui inclut les fichiers d'entrée et les fichiers de sortie une fois l'analyse terminée.

## Créer une exécution de flux de travail utilisateur

Prérequis :

- Un projet doit contenir au moins un échantillon, et cet échantillon doit avoir des fichiers appariés téléversés.
- Vous devez avoir au moins le rôle Analyste pour le projet ou le groupe à partir duquel vous créerez l'exécution de flux de travail.

Pour créer une exécution de flux de travail utilisateur :

1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) ou le [groupe](../organization/groups/manage#view-groups) qui contient les échantillons que vous souhaitez analyser
2. Dans la barre latérale gauche, sélectionnez **Échantillons**
3. Cochez la case de chaque échantillon que vous souhaitez inclure dans l'analyse
4. Cliquez sur ![workflow_execution_btn](./assets/rocket_launch.svg)
5. Sélectionnez un pipeline dans la boîte de dialogue
6. La boîte de dialogue suivante contient une liste de paramètres que vous devez saisir et/ou confirmer. Cette liste comprend des paramètres spécifiques au pipeline sélectionné, ainsi que des paramètres optionnels tels que le nom du flux de travail, la notification par courriel et les mises à jour des échantillons à la fin du flux de travail.

## Configurer les exécutions de flux de travail automatisées

Prérequis :

- Un projet et au moins le rôle Responsable pour ce projet.

Pour configurer les exécutions de flux de travail automatisées :

1. Naviguez vers le [projet](../project/projects/manage-projects#view-projects-you-have-access-to) pour lequel vous souhaitez configurer les exécutions de flux de travail automatisées
2. Dans la barre latérale gauche, sélectionnez **Paramètres**
3. Dans le menu déroulant **Paramètres**, sélectionnez **Exécutions de flux de travail automatisées**
4. Cliquez sur **Nouvelle exécution de flux de travail automatisée**
5. Sélectionnez un pipeline dans la boîte de dialogue
6. La boîte de dialogue suivante contient une liste de paramètres que vous devez saisir et/ou confirmer. Cette liste comprend des paramètres spécifiques au pipeline sélectionné, ainsi que des paramètres optionnels tels que le nom du flux de travail, la notification par courriel et les mises à jour des échantillons à la fin du flux de travail.

Une fois configurée, chaque fois que des fichiers appariés sont téléversés vers un échantillon appartenant à ce projet, une exécution de flux de travail avec ces paramètres sélectionnés sera exécutée.
