---
sidebar_position: 1
id: group-and-project-members
title: Membres de groupe et de projet
---

Dans IRIDA Next, les membres sont les utilisateurs et les groupes qui ont accès à votre projet. Chaque membre a un rôle, qui détermine ce qu'il peut faire ou accéder dans le projet.

## Types d'appartenance

IRIDA Next a quatre types d'appartenance

| Type d'appartenance | Processus                                                                               |
| :------------------ | :-------------------------------------------------------------------------------------- |
| Direct              | L'utilisateur est ajouté directement au groupe ou au projet                             |
| Hérité              | L'utilisateur est membre d'un groupe ancêtre                                            |
| Partagé direct      | L'utilisateur est un membre direct d'un groupe avec lequel l'espace de noms est partagé |
| Partagé hérité      | L'utilisateur est un membre hérité d'un groupe avec lequel l'espace de noms est partagé |

## Appartenance directe

Lorsque le projet appartient à un groupe, si un utilisateur est ajouté directement à un projet et que cet utilisateur est membre d'un groupe parent ou de ses ancêtres, le rôle minimum que l'utilisateur pourrait se voir attribuer dans le projet est son rôle maximum dans le groupe parent et ses ancêtres.

Par exemple :

- L'utilisateur 0 est membre du Groupe 1 avec le rôle **Responsable**
- Le Groupe 1 a un sous-groupe Sous-groupe 1
- Le Projet 1 appartient au Sous-groupe 1
- Les seuls rôles que l'utilisateur 0 peut se voir attribuer dans le projet sont **Responsable** et **Propriétaire**

## Appartenance héritée

Lorsque le projet appartient à un groupe, les membres de ce projet hériteront de leur rôle du groupe et de ses ancêtres.

Par exemple :

- L'utilisateur 0 est membre du Groupe 1 avec un rôle **Responsable**
- Le Groupe 1 a un sous-groupe Sous-groupe 1
- Le Projet 1 appartient au Sous-groupe 1
- L'utilisateur 0 a l'appartenance héritée dans le Projet 1 par l'ancêtre (Groupe 1) du Sous-groupe 1 avec le rôle **Responsable**

## Appartenance partagée directe

Lorsque le projet appartient à un groupe, si le projet est partagé directement avec un autre groupe, le minimum du niveau d'accès effectif du groupe et du niveau d'accès de l'utilisateur dans son groupe s'applique

Par exemple :

- L'utilisateur 0 est membre du Groupe A avec le rôle **Analyste**
- Le Projet 1 appartient au Groupe B
- Le Projet 1 est partagé avec le Groupe A avec un niveau d'accès de groupe **Responsable**
- L'utilisateur 0 aura un rôle maximum d'**Analyste** de son groupe lors de l'accès au Projet 1

## Appartenance partagée héritée

Lorsque le projet appartient à un groupe et que le groupe est partagé avec un autre groupe dans lequel un utilisateur a une appartenance, le minimum du niveau d'accès effectif du groupe et du niveau d'accès de l'utilisateur dans son groupe s'applique

Par exemple :

- L'utilisateur 0 est membre du Groupe A avec le rôle **Analyste**
- Le Projet 1 appartient au Groupe B
- Le Groupe B est partagé avec le Groupe A avec un niveau d'accès de groupe **Mainteneur**
- L'utilisateur 0 aura un rôle maximum d'**Analyste** de son groupe lors de l'accès au Groupe B et à ses descendants (sous-groupes et projets)

## Ajouter des membres à un groupe

Ajoutez des utilisateurs à un groupe afin qu'ils puissent avoir accès aux sous-groupes et aux projets au sein du groupe

Prérequis :

Vous devez avoir au moins un rôle **Responsable**, ou vous devez être le propriétaire du groupe

Pour ajouter un utilisateur à un groupe :

1. Dans la barre latérale gauche, sélectionnez **Groupes**, et trouvez votre groupe
2. Dans la barre latérale gauche, sélectionnez **Membres**
3. Cliquez sur le bouton **Ajouter un membre**
4. Sélectionnez l'utilisateur que vous souhaitez ajouter au groupe
5. Sélectionnez un niveau d'accès (rôle)
6. Sélectionnez une **Expiration d'accès** optionnelle
7. Cliquez sur le bouton **Ajouter un membre au groupe**

## Modifier les membres d'un groupe ou d'un projet

Prérequis :

Vous devez avoir au moins un rôle **Mainteneur**, ou vous devez être le propriétaire du groupe

1. Dans la barre latérale gauche, sélectionnez **Projets** ou **Groupes**
2. Sélectionnez le projet ou le groupe
3. Dans la barre latérale gauche, sélectionnez **Membres**
4. Trouvez le membre que vous souhaitez mettre à jour

Pour mettre à jour le rôle d'un membre :

1. Dans la colonne **Niveau d'accès**, sélectionnez le nouveau rôle pour le membre dans le menu déroulant

Pour mettre à jour l'expiration d'accès d'un membre :

1. Dans la colonne **Expiration**, sélectionnez l'entrée et définissez une date à l'aide du sélecteur de date.

## Ajouter des membres à un projet

Ajoutez des utilisateurs à un projet afin qu'ils deviennent des membres directs et aient la permission d'effectuer des actions.

Prérequis :

Vous devez avoir au moins un rôle **Responsable**, ou le projet doit être sous votre espace de noms utilisateur.

Pour ajouter un utilisateur direct à un projet :

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Membres**
4. Cliquez sur le bouton **Ajouter un membre**
5. Sélectionnez l'utilisateur que vous souhaitez ajouter au projet
6. Sélectionnez un niveau d'accès (rôle)
7. Sélectionnez une **Expiration d'accès** optionnelle
8. Cliquez sur le bouton **Ajouter un membre au projet**

## Quels rôles vous pouvez attribuer

Le rôle maximum que vous pouvez attribuer dépend de si vous avez le rôle **Propriétaire** ou **Responsable** pour l'ascendance du groupe. Par exemple, le rôle maximum que vous pouvez définir est :

- Propriétaire, si vous avez le rôle Propriétaire pour le projet.
- Responsable, si vous avez le rôle Responsable sur le projet.

## Retirer un membre d'un projet

Si un utilisateur est :

- Un membre direct d'un projet, vous pouvez le retirer directement du projet.
- Un membre hérité d'un groupe parent, vous ne pouvez le retirer que du groupe parent lui-même.

Prérequis :

- Pour retirer les membres directs qui ont le :
  - Rôle Responsable, Développeur, Analyste, Téléverseur ou Invité, vous devez avoir le rôle Responsable ou Propriétaire.
  - Rôle Propriétaire, vous devez également avoir un rôle Propriétaire.

Pour retirer un membre d'un projet :

1. Dans la barre latérale gauche, sélectionnez **Projets**
2. Sélectionnez le projet
3. Dans la barre latérale gauche, sélectionnez **Membres**
4. Sur le côté droit de la ligne pour le membre que vous souhaitez retirer, cliquez sur **Retirer**.
5. Confirmez que vous souhaitez retirer le membre du projet dans la fenêtre contextuelle en cliquant sur le bouton **OK**

## Retirer un membre d'un groupe

Si un utilisateur est :

- Un membre direct d'un groupe, vous pouvez le retirer directement du groupe.
- Un membre hérité d'un groupe parent, vous ne pouvez le retirer que du groupe parent lui-même.

Prérequis :

- Pour retirer les membres directs qui ont le :
  - Rôle Responsable, Développeur, Analyste, Téléverseur ou Invité, vous devez avoir le rôle Responsable.
  - Rôle Propriétaire, vous devez avoir le rôle Propriétaire.

Pour retirer un membre d'un groupe :

1. Dans la barre latérale gauche, sélectionnez **Groupes**
2. Sélectionnez le groupe
3. Dans la barre latérale gauche, sélectionnez **Membres**
4. Sur le côté droit de la ligne pour le membre que vous souhaitez retirer, cliquez sur **Retirer**.
5. Confirmez que vous souhaitez retirer le membre du groupe dans la fenêtre contextuelle en cliquant sur le bouton **OK**
