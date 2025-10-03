---
sidebar_position: 1
id: getting-started
title: Démarrage
---

Dans IRIDA Next, vous pouvez télécharger des données de plusieurs échantillons ou tous les fichiers associés à une exécution de flux de travail en une seule fois en créant une exportation de données.

## Types d'exportation

Il existe trois types d'exportation dans IRIDA Next :

| Type d'exportation | Description                                                                                                                                      |
| :----------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| Échantillon        | Permet aux utilisateurs de sélectionner n'importe quel nombre d'échantillons appartenant à un groupe ou à un projet et de télécharger tous les fichiers associés. |
| Liste linéaire     | Permet aux utilisateurs de sélectionner n'importe quel nombre d'échantillons appartenant à un groupe ou à un projet et de télécharger toutes les métadonnées associées. |
| Analyse            | Permet aux utilisateurs de télécharger tous les fichiers associés à une exécution de flux de travail.                                           |

## Exigences

Les éléments suivants sont requis pour créer une exportation :
* Exportation d'échantillon
  * Projet ayant au moins un échantillon associé, et des fichiers téléversés vers l'échantillon.
  * Au moins le rôle Analyste pour le projet ou le groupe contenant les échantillons à exporter.
* Exportation de liste linéaire
  * Projet ayant au moins un échantillon associé contenant des métadonnées.
  * Au moins le rôle Analyste pour le projet ou le groupe contenant les échantillons à exporter.
* Exportation d'analyse
  * Exécution de flux de travail utilisateur
    * Une exécution de flux de travail utilisateur dans l'état terminé.
  * Exécution de flux de travail automatisée
    * Projet ayant au moins une exécution de flux de travail automatisée dans l'état terminé.
    * Au moins le rôle Analyste pour le projet contenant l'exécution de flux de travail automatisée.

## Contenu de l'exportation

Les exportations permettent aux utilisateurs de télécharger leurs données depuis IRIDA Next en un seul clic. Suivez ces [étapes](../export/working-with-exports) pour apprendre à travailler avec les exportations.

Exportations d'échantillon et d'analyse :
* Les fichiers sont ajoutés à un seul dossier compressé. En plus des fichiers exportés sélectionnés par l'utilisateur, trois fichiers supplémentaires sont inclus :
  * Chaque exportation inclut un fichier **manifest.json** et **manifest.txt** qui contient un aperçu de ce qui est inclus dans l'exportation.
  * Chaque exportation d'analyse inclut un fichier **summary.txt.gz** qui contient le résumé du pipeline.

Exportations de liste linéaire :
* Le contenu de l'exportation sera contenu dans un seul fichier du format choisi (.csv ou .xlsx).

## Statuts d'exportation

Les exportations auront soit un statut **En traitement** ou **Prêt** qui leur est attribué.
  * Lorsqu'une exportation est **En traitement**, IRIDA Next est en train de créer votre exportation et, par conséquent, votre exportation n'est pas disponible pour téléchargement.
  * Une fois que le statut de l'exportation est **Prêt**, l'exportation est prête à être téléchargée. Un [aperçu](../export/working-with-exports#view-single-export) du contenu de l'exportation pour les exportations d'échantillon et d'analyse est également visible sur IRIDA Next une fois que le statut de l'exportation est **Prêt**.

Une fois que le statut de l'exportation est défini sur **Prêt**, vous aurez **3 jours ouvrables** pour télécharger l'exportation avant qu'elle ne soit automatiquement supprimée. Vous pouvez choisir de recevoir un [courriel](../export/working-with-exports#create-sample-export) lors de la création de l'exportation pour vous assurer de ne pas manquer la fenêtre de téléchargement.
