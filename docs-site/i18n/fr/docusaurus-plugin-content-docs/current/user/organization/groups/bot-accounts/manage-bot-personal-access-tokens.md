---
sidebar_position: 4
id: manage-bot-PAT
title: Gérer les jetons d'accès personnels des comptes de robot
---

Les jetons d'accès personnels (PAT) sont nécessaires pour utiliser l'API GraphQL d'IRIDA Next. Consultez [Authentification avec les jetons d'accès personnels](/docs/extend/graphql#authentication-with-personal-access-tokens) pour plus d'informations.

## Voir le jeton d'accès personnel

Prérequis :

- Vous devez avoir au moins un rôle **Mainteneur**.

Pour voir les jetons d'accès personnels des comptes de robot au sein d'un groupe :

1. Dans la barre latérale gauche, sélectionnez **Groupes** et trouvez votre groupe.
2. Dans la barre latérale gauche, sélectionnez **Paramètres > Comptes de robot**.
3. Cliquez sur le lien du total **Jetons actifs** dans la ligne du jeton d'accès personnel du compte de robot que vous souhaitez voir. Une liste des jetons d'accès personnels actifs sera affichée.

## Générer un jeton d'accès personnel

Prérequis :

- Vous devez avoir au moins un rôle **Mainteneur**.

Pour générer un jeton d'accès personnel de compte de robot au sein d'un groupe :

1. Dans la barre latérale gauche, sélectionnez **Groupes** et trouvez votre groupe.
2. Dans la barre latérale gauche, sélectionnez **Paramètres > Comptes de robot**.
3. Sur le côté droit de la ligne pour le compte de robot, cliquez sur le lien **Générer un nouveau jeton**.
4. Entrez le nom du jeton dans le champ **Nom**.
5. Sélectionnez un niveau d'accès.
6. Définissez une date d'expiration optionnelle.
7. Sélectionnez au moins une portée.
8. Cliquez sur le bouton **Soumettre**.

## Révoquer un jeton d'accès personnel

Prérequis :

- Vous devez avoir au moins un rôle **Mainteneur**.

Pour révoquer un jeton d'accès personnel de compte de robot au sein d'un groupe :

1. Dans la barre latérale gauche, sélectionnez **Groupes** et trouvez votre groupe.
2. Dans la barre latérale gauche, sélectionnez **Paramètres > Comptes de robot**.
3. Cliquez sur le lien du total **Jetons actifs** dans la ligne du jeton d'accès personnel du compte de robot que vous souhaitez révoquer. Une liste des jetons d'accès personnels actifs sera affichée.
4. Sur le côté droit de la ligne pour le jeton d'accès personnel du compte de robot, cliquez sur le bouton **Révoquer**.
5. Confirmez que vous souhaitez révoquer le jeton d'accès personnel du compte de robot en cliquant sur le bouton **Confirmer**.
