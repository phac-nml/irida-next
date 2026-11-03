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
  client_id: VOTRE_ID_CLIENT
  client_secret: VOTRE_SECRET_CLIENT
  tenant_id: VOTRE_ID_LOCATAIRE
  # Facultatif. Remplace l'audience attendue (revendication 'aud') pour les jetons
  # porteurs de l'API (voir « Authentification avec les jetons Entra ID » dans la
  # documentation GraphQL). Par défaut, il s'agit du client_id et de sa forme
  # URI d'ID d'application (api://VOTRE_ID_CLIENT).
  # api_audience: VOTRE_URI_ID_APPLICATION_API
```

Pour permettre aux intégrations d'authentifier les requêtes de l'API GraphQL en tant qu'utilisateur Entra ID connecté (au lieu
d'un jeton d'accès personnel partagé), l'inscription d'application doit exposer une permission déléguée (portée) `access_as_user`,
en plus des portées `api`/`read_api` utilisées pour contrôler l'accès aux requêtes/mutations. Voir
[Authentification avec les jetons Entra ID](../extend/graphql.md#authentication-with-entra-id-bearer-tokens) pour plus de
détails.

#### SAML

Pour SAML, vous aurez besoin des lignes suivantes

```yml
saml:
  idp_sso_service_url: VOTRE_URL_SERVICE_SSO_IDP_SAML
  sp_entity_id: VOTRE_ID_ENTITE_SP_SAML
  idp_cert: VOTRE_CERT_IDP_SAML
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
