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
détails sur le flux de requête/réponse, et la section ci-dessous pour savoir comment configurer l'inscription d'application
Entra elle-même.

##### Configuration de l'inscription d'application Entra pour l'accès à l'API On-Behalf-Of

Cette section s'adresse aux administrateurs Entra qui doivent permettre à une intégration de confiance (telle que BDIP)
d'appeler l'API GraphQL d'IRIDA Next en tant qu'utilisateur connecté via le
[flux On-Behalf-Of (OBO)](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow),
au lieu d'utiliser un jeton d'accès personnel partagé.

Deux inscriptions d'application sont impliquées :

- **L'inscription d'application d'IRIDA Next** — celle déjà utilisée pour la connexion (le `client_id`/`tenant_id`
  configuré ci-dessus). C'est la **ressource** à laquelle on accède; elle doit exposer l'API et ses portées.
- **L'inscription d'application de l'intégration** (p. ex. celle de BDIP) — le **client** qui effectue l'échange OBO
  au nom de l'utilisateur. Il s'agit d'une inscription d'application distincte, appartenant à l'intégration, et non
  à IRIDA Next.

**1. Exposer l'API d'IRIDA Next et définir les portées**

Dans le portail Azure/Entra, ouvrez l'inscription d'application d'IRIDA Next et accédez à **Exposer une API** :

1. Si aucun **URI d'ID d'application** n'est défini, cliquez sur **Définir** et acceptez la valeur par défaut
   (`api://<id-client>`) ou définissez un URI personnalisé. Si vous choisissez un URI personnalisé qui ne correspond
   pas à `api://<id-client>`, définissez l'informations d'identification `api_audience` indiquée ci-dessus pour
   qu'elle corresponde.
2. Cliquez sur **Ajouter une portée** et ajoutez les portées suivantes (chacune nécessite un nom de portée, qui peut
   consentir, ainsi qu'un nom d'affichage et une description de consentement administrateur/utilisateur) :
   - `access_as_user` — requise sur chaque jeton porteur; représente « agir en tant qu'utilisateur connecté ».
     Sans cette portée, IRIDA Next rejette entièrement le jeton.
   - `api` — accorde un accès en lecture et en écriture à l'API GraphQL (équivalent à la portée `api` d'un jeton
     d'accès personnel).
   - `read_api` — accorde un accès en lecture seule à l'API GraphQL (équivalent à la portée `read_api` d'un jeton
     d'accès personnel).

**2. Autoriser l'application cliente de l'intégration**

Toujours sous **Exposer une API**, dans la section **Applications clientes autorisées**, cliquez sur **Ajouter une
application cliente** et ajoutez l'**ID d'application (client)** de l'intégration (p. ex. celui de BDIP, pas celui
d'IRIDA Next). Sélectionnez la portée `access_as_user`, ainsi que `api` et/ou `read_api` selon ce que l'intégration
doit être autorisée à faire.

Pré-autoriser le client de cette manière permet à l'échange OBO de réussir sans invite de consentement interactive
administrateur/utilisateur. Autrement, l'inscription d'application de l'intégration peut demander ces éléments
comme **permissions d'API déléguées** par rapport à l'inscription d'application d'IRIDA Next (sous **Permissions
d'API > Ajouter une permission > Mes API**), un administrateur Entra accordant le consentement administrateur pour
le locataire — les deux approches sont suffisantes, la pré-autorisation étant simplement le modèle le plus courant
pour les intégrations de service à service.

**3. Confirmer que l'intégration est configurée comme client confidentiel**

Le flux OBO exige que l'intégration s'authentifie elle-même avec un secret client ou un certificat lors de
l'échange du jeton de l'utilisateur, en plus de présenter le jeton original de l'utilisateur. Ceci est configuré
sur l'inscription d'application/l'infrastructure de l'intégration elle-même, et non sur celle d'IRIDA Next.

**4. Répéter pour d'autres intégrations**

Étant donné que l'audience (revendication `aud`) d'un jeton OBO identifie toujours IRIDA Next (la ressource), et
non le client appelant, un nombre quelconque d'intégrations distinctes peuvent être autorisées de cette manière
par rapport à la même inscription d'application d'IRIDA Next : il suffit de répéter l'étape 2 pour l'ID client de
chaque intégration. Aucune modification n'est nécessaire aux informations d'identification `client_id`/`tenant_id`/
`api_audience` d'IRIDA Next pour prendre en charge des intégrations supplémentaires.

**5. Valider**

Une fois configurée, l'intégration obtient un jeton d'accès via le flux OBO en demandant
`api://<ID-CLIENT-IRIDA-NEXT>/access_as_user` (plus `api` et/ou `read_api`), et le présente à IRIDA Next comme
décrit dans [Authentification avec les jetons Entra ID](../extend/graphql.md#authentication-with-entra-id-bearer-tokens).
L'utilisateur effectuant l'action doit déjà s'être connecté à IRIDA Next au moins une fois via le fournisseur
`entra_id`, car IRIDA Next recherche le compte local à partir des revendications `oid`/`tid` du jeton plutôt que
d'en créer un.

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
