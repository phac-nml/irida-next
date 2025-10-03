---
sidebar_position: 2
id: mail
title: Configuration des options de courriel
---

## Configuration

Les options suivantes peuvent être définies dans le fichier d'informations d'identification rails.

```yml
action_mailer:
  default_from: <une adresse courriel>
  smtp_options:
    address: <un serveur smtp>
    port: <un port smtp>
    ...
```

### default_from

L'adresse courriel par défaut de tous les courriels envoyés depuis l'application.

### smtp_options

Peut être utilisé pour se connecter à un serveur smtp spécifique à utiliser pour envoyer les courriels.

Pour plus d'informations, consultez la documentation officielle Ruby on Rails [Action Mailer Configuration](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration).
