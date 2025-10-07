---
sidebar_position: 3
id: sample-metadata
title: Métadonnées d'échantillon
---

Les métadonnées peuvent être ajoutées aux échantillons pour leur donner toute information supplémentaire requise par les utilisateurs.

Un échantillon ne peut pas avoir de métadonnées avec la même clé, et les métadonnées ajoutées par une analyse ne peuvent pas être écrasées par un utilisateur.

## Voir les métadonnées

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Cliquez sur le bouton à bascule à côté de **Métadonnées**

Le tableau des échantillons se mettra à jour avec toutes les métadonnées des échantillons.

Pour voir les métadonnées d'un échantillon individuel :

5. Sélectionnez l'échantillon
6. Cliquez sur l'onglet **Métadonnées**

## Ajouter des métadonnées

Prérequis :

- Vous devez avoir au moins un rôle **Responsable** pour le projet de l'échantillon
- Un échantillon ajouté au projet

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Sélectionnez l'échantillon
5. Cliquez sur l'onglet **Métadonnées**
6. Cliquez sur **Ajouter des métadonnées**

Une boîte de dialogue apparaîtra où vous pourrez ajouter de nouvelles métadonnées.

## Mettre à jour les métadonnées

Prérequis :

- Vous devez avoir au moins un rôle **Responsable** pour le projet de l'échantillon
- Un échantillon avec des métadonnées existantes ajouté au projet

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Sélectionnez l'échantillon
5. Cliquez sur l'onglet **Métadonnées**
6. Cliquez sur le lien **Mettre à jour** des métadonnées que vous souhaitez mettre à jour

Une boîte de dialogue apparaîtra où vous pourrez mettre à jour les métadonnées.

## En savoir plus sur l'importation de métadonnées

L'importation de métadonnées vous permet d'ajouter plusieurs champs de métadonnées à plusieurs échantillons en une seule fois. Cela nécessite une feuille de calcul au format .csv, .tsv, .xls ou .xlsx.

Ceci est un exemple du format de feuille de calcul attendu :

| nomEchantillon | champMetadonnees1 | champMetadonnees2 | champMetadonnees3 |
| :------------- | :---------------- | :---------------- | :---------------- |
| echantillon1   | valeur1           | valeur2           | valeur3           |
| echantillon2   | valeur4           | valeur5           | valeur6           |

Les métadonnées suivantes seront ajoutées :

- Échantillon1 :

  | cle               | valeur  |
  | :---------------- | :------ |
  | champMetadonnees1 | valeur1 |
  | champMetadonnees2 | valeur2 |
  | champMetadonnees3 | valeur3 |

- Échantillon2 :

  | cle               | valeur  |
  | :---------------- | :------ |
  | champMetadonnees1 | valeur4 |
  | champMetadonnees2 | valeur5 |
  | champMetadonnees3 | valeur6 |

Lors de la création de la feuille de calcul, vous devez avoir une colonne qui contient un identifiant d'échantillon. L'identifiant est sensible à la casse et peut contenir soit les noms d'échantillon, soit les PUID. Lors de l'importation de métadonnées à partir d'un **projet**, l'identifiant d'échantillon peut être soit le **nom de l'échantillon, soit le PUID**. Si vous importez des métadonnées à partir d'un **groupe**, l'identifiant d'échantillon doit être le **PUID de l'échantillon**.

**An important note:** When importing a metadata spreadsheet, you will be asked if you'd like to **Delete metadata with empty values**. If this is **selected**, any metadata with a key and empty value will be **deleted**. However, if this **not selected**, any metadata fields without an associated value will be ignored and those metadata keys will not be removed from the sample if present.

Par exemple, si les métadonnées ci-dessus étaient importées et ajoutées à Échantillon1 et Échantillon2, et que la feuille de calcul suivante était ensuite importée :

| nomEchantillon | champMetadonnees1 | champMetadonnees2 | champMetadonnees3 | champMetadonnees4 |
| :------------- | :---------------- | :---------------- | :---------------- | :---------------- |
| echantillon1   |                   | nouvelleValeur2   | nouvelleValeur3   | autreValeur1      |
| echantillon2   | nouvelleValeur4   |                   | nouvelleValeur6   | autreValeur2      |

Cela résulterait en les métadonnées d'échantillon suivantes :

- If **Delete metadata with empty values** was **checked**:

  - Échantillon1 :

    | cle               | valeur          |
    | :---------------- | :-------------- |
    | champMetadonnees2 | nouvelleValeur2 |
    | champMetadonnees3 | nouvelleValeur3 |
    | champMetadonnees4 | autreValeur1    |

  - Échantillon2 :

    | cle               | valeur          |
    | :---------------- | :-------------- |
    | champMetadonnees1 | nouvelleValeur4 |
    | champMetadonnees3 | nouvelleValeur6 |
    | champMetadonnees4 | autreValeur2    |

- If **Delete metadata with empty values** was **not checked**:

  - Échantillon1 :

    | cle               | valeur          |
    | :---------------- | :-------------- |
    | champMetadonnees1 | valeur1         |
    | champMetadonnees2 | nouvelleValeur2 |
    | champMetadonnees3 | nouvelleValeur3 |
    | champMetadonnees4 | autreValeur1    |

  - Échantillon2 :

    | cle               | valeur          |
    | :---------------- | :-------------- |
    | champMetadonnees1 | nouvelleValeur4 |
    | champMetadonnees2 | valeur5         |
    | champMetadonnees3 | nouvelleValeur6 |
    | champMetadonnees4 | autreValeur2    |

## Étapes pour importer des métadonnées

Prérequis :

- Vous devez avoir au moins un rôle **Responsable** pour le projet ou le groupe de l'échantillon
- Un échantillon ajouté au projet ou au groupe

1. Dans la barre latérale gauche, sélectionnez **Projets** ou **Groupes**
2. Sélectionnez le projet ou le groupe
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Cliquez sur **Importer des métadonnées**

A dialog will pop-up to select the spreadsheet to be imported. After selecting the spreadsheet file, identify which column contains the sample identifier and whether you'd like to [Delete metadata with empty values](sample-metadata#learn-about-importing-metadata).

## Supprimer des métadonnées

Prérequis :

- Vous devez avoir au moins un rôle **Responsable** pour le projet de l'échantillon
- Un échantillon avec des métadonnées existantes ajouté au projet

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Sélectionnez l'échantillon
5. Cliquez sur l'onglet **Métadonnées**
6. Cochez les cases des métadonnées que vous souhaitez supprimer.
7. Cliquez sur **Supprimer les métadonnées**
