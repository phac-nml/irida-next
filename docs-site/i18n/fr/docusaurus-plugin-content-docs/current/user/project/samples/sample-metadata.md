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

| Sample Name | MetadataField1 | MetadataField2 | MetadataField3 |
| :---------- | :------------- | :------------- | :------------- |
| Sample 1    | value1         | value2         | value3         |
| Sample 2    | value4         | value5         | value6         |

Les métadonnées suivantes seront ajoutées :

- Sample 1 :

  | Key            | Value  |
  | :------------- | :----- |
  | MetadataField1 | value1 |
  | MetadataField2 | value2 |
  | MetadataField3 | value3 |

- Sample 2 :

  | Key            | Value  |
  | :------------- | :----- |
  | MetadataField1 | value4 |
  | MetadataField2 | value5 |
  | MetadataField3 | value6 |

Lors de la création de la feuille de calcul, vous devez avoir une colonne qui contient un identifiant d'échantillon. L'identifiant est sensible à la casse et peut contenir soit les noms d'échantillon, soit les PUID. Lors de l'importation de métadonnées à partir d'un **projet**, l'identifiant d'échantillon peut être soit le **nom de l'échantillon, soit le PUID**. Si vous importez des métadonnées à partir d'un **groupe**, l'identifiant d'échantillon doit être le **PUID de l'échantillon**.

**Une note importante :** Lors de l'importation d'une feuille de calcul de métadonnées, il vous sera demandé si vous souhaitez **Ignorer les valeurs vides**. Si cela est **sélectionné**, tous les champs de métadonnées sans valeur associée seront ignorés et ces clés de métadonnées ne seront pas supprimées de l'échantillon si elles sont présentes. Cependant, si cela n'est **pas sélectionné**, tous les échantillons avec la clé de métadonnées et une valeur vide seront **supprimés**.

Par exemple, si les métadonnées ci-dessus étaient importées et ajoutées à Sample 1 et Sample 2, et que la feuille de calcul suivante était ensuite importée :

| Sample Name | MetadataField1 | MetadataField2 | MetadataField3 | MetadataField4 |
| :---------- | :------------- | :------------- | :------------- | :------------- |
| Sample 1    |                | newValue2      | newValue3      | anotherValue1  |
| Sample 2    | newValue4      |                | newValue6      | anotherValue2  |

Cela résulterait en les métadonnées d'échantillon suivantes :

- Si **Ignorer les valeurs vides** était **coché** :

  - Sample 1 :

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | value1        |
    | MetadataField2 | newValue2     |
    | MetadataField3 | newValue3     |
    | MetadataField4 | anotherValue1 |

  - Sample 2 :

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | newValue4     |
    | MetadataField2 | value5        |
    | MetadataField3 | newValue6     |
    | MetadataField4 | anotherValue2 |

- Si **Ignorer les valeurs vides** n'était **pas coché** :

  - Sample 1 :

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField2 | newValue2     |
    | MetadataField3 | newValue3     |
    | MetadataField4 | anotherValue1 |

  - Sample 2 :

    | Key            | Value         |
    | :------------- | :------------ |
    | MetadataField1 | newValue4     |
    | MetadataField3 | newValue6     |
    | MetadataField4 | anotherValue2 |

## Étapes pour importer des métadonnées

Prérequis :

- Vous devez avoir au moins un rôle **Responsable** pour le projet ou le groupe de l'échantillon
- Un échantillon ajouté au projet ou au groupe

1. Dans la barre latérale gauche, sélectionnez **Projets** ou **Groupes**
2. Sélectionnez le projet ou le groupe
3. Dans la barre latérale gauche, sélectionnez **Échantillons**
4. Cliquez sur **Importer des métadonnées**

Une boîte de dialogue apparaîtra pour sélectionner la feuille de calcul à importer. Après avoir sélectionné le fichier de feuille de calcul, identifiez quelle colonne contient l'identifiant d'échantillon et si vous souhaitez [Ignorer les valeurs vides](sample-metadata#learn-about-importing-metadata).

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
