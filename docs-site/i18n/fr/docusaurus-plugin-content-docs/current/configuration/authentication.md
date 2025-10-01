---
sidebar_position: 1
id: authentication
title: Connexion à un serveur d'authentification
---

## Configuration

### Activer l'authentification à distance

Par défaut, l'authentification à distance est désactivée. Pour l'activer, vous devrez modifier le fichier de configuration `config/authentication/auth_config.yml`

Le fichier auth_config.yml a le format ci-dessous.

```yml
development:
  omniauth_providers: [developer]
  # developer_text:
  # developer_icon:
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:

test:
  omniauth_providers: [developer, saml, entra_id]
  # developer_text:
  # developer_icon:
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:

# production:
  # omniauth_providers: []
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:
```

Pour votre environnement de production, décommentez et modifiez les lignes `production` pertinentes.

Pour Entra ID, anciennement Azure Active Directory

```yml
production:
  omniauth_providers: [entra_id]
```

Pour SAML

```yml
production:
  omniauth_providers: [saml]
```

### Informations d'identification

Vous devrez configurer les informations d'identification du serveur d'authentification dans le fichier d'informations d'identification secrètes d'IRIDA Next.

Vous pouvez modifier ce fichier avec la commande suivante.

```bash
EDITOR="vim --nofork" bin/rails credentials:edit
```

#### Entra ID (anciennement Azure Active Directory V2)

Pour Entra, vous aurez besoin des lignes suivantes

```yml
entra_id:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET
  tenant_id: YOUR_TENANT_ID
```

#### SAML

Pour SAML, vous aurez besoin des lignes suivantes

```yml
saml:
  idp_sso_service_url: YOUR_SAML_IDP_SSO_SERVICE_URL
  sp_entity_id: YOUR_SAML_SP_ENTITY_ID
  idp_cert: YOUR_SAML_IDP_CERT
```

## Personnalisation supplémentaire

Vous pouvez modifier le nom d'affichage et l'icône pour correspondre à votre organisation.

Dans le fichier `config/authentication/auth_config.yml`, modifiez les champs `_text` et `_icon` appropriés pour votre configuration Entra ou SAML.

Mettez le nom de votre organisation dans le champ `_text`.

Placez un fichier d'icône `.svg` dans le répertoire `config/authentication/icons/` et ajoutez le nom de fichier au champ `_icon`.

Exemple :

```yml
production:
  omniauth_providers: [entra_id]
  # saml_text:
  # saml_icon:
  entra_id_text: Tyrell Corporation
  entra_id_icon: tyrell.svg
```
