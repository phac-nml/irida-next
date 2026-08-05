---
sidebar_position: 8
id: system_accounts
title: Comptes système
---

## Configuration

Pour donner à un utilisateur l'accès `system`, ajoutez l(es) adresse(s) courriel de l'utilisateur au fichier d'identifiants (credentials). Si l'accès `system` d'un utilisateur doit être révoqué, supprimez l'adresse courriel de l'utilisateur du fichier d'identifiants.

Modifiez le fichier d'identifiants de votre environnement (développement, production, etc.) avec la commande suivante :

`EDITOR="vim --nofork" bin/rails credentials:edit --environment ENVIRONMENT`

[En savoir plus sur le fichier d'identifiants Rails ici](https://guides.rubyonrails.org/security.html#custom-credentials)

Suivez le format ci‑dessous :

```yml
system_accounts:
  user_emails:
    - utilisateur1@courriel.com
    - utilisateur2@courriel.com
    - utilisateur3@courriel.com
    ...
```

## Fonctionnalités

Les utilisateurs `system` ont accès aux fonctionnalités supplémentaires suivantes en plus de leur accès habituel à IRIDA Next :

- Interroger les métriques via l'API GraphQL (groupes et projets)
