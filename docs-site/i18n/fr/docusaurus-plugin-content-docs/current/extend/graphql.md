---
sidebar_position: 1
id: graphql
title: API GraphQL
---

[GraphQL](https://graphql.org/) est un langage de requête pour les API. Vous pouvez l'utiliser pour demander exactement les données dont vous avez besoin, et donc limiter le nombre de requêtes dont vous avez besoin.

Les données GraphQL sont organisées en types, de sorte que votre client peut utiliser [des bibliothèques GraphQL côté client](https://graphql.org/code/#graphql-clients) pour consommer l'API et éviter l'analyse manuelle.

L'API GraphQL est [sans version](https://graphql.org/learn/best-practices/#versioning).

## Accéder à GraphIQL

Le moyen le plus simple d'utiliser l'API GraphQL est via `GraphIQL` en utilisant les étapes suivantes.

1. Connectez-vous à IRIDA Next `http://my.irida.server/users/sign_in`
2. Allez à l'URL GraphIQL `http://my.irida.server/graphiql`

Vous serez accueilli avec l'outil intégré au navigateur pour écrire, valider et tester des requêtes GraphQL.

Pour plus d'informations sur GraphIQL, consultez [la documentation officielle](https://graphql-dotnet.github.io/docs/getting-started/graphiql/)

## Exemples GraphQL

<table>
<tr>
<td> Exemple </td> <td> Requête </td> <td> Réponse </td>
</tr>
<tr>
<td> Obtenir l'utilisateur actuel </td>
<td>

```graphql
query {
  currentUser {
    email
  }
}
```

</td>
<td>

```json
{
  "data": {
    "currentUser": {
      "email": "user0@email.com"
    }
  }
}
```

</td>
</tr>
<tr>
<td> Obtenir les échantillons </td>
<td>

```graphql
query {
  samples(first: 5) {
    nodes {
      name
      id
    }
  }
}
```

</td>
<td>

```json
{
  "data": {
    "samples": {
      "nodes": [
        {
          "name": "Bacillus anthracis/Éclosion 2022 Échantillon 1",
          "id": "gid://irida/Sample/1"
        },
        {
          "name": "Bacillus anthracis/Éclosion 2022 Échantillon 2",
          "id": "gid://irida/Sample/2"
        },
        {
          "name": "Bacillus anthracis/Éclosion 2022 Échantillon 3",
          "id": "gid://irida/Sample/3"
        },
        {
          "name": "Bacillus anthracis/Éclosion 2022 Échantillon 4",
          "id": "gid://irida/Sample/4"
        },
        {
          "name": "Bacillus anthracis/Éclosion 2022 Échantillon 5",
          "id": "gid://irida/Sample/5"
        }
      ]
    }
  }
}
```

</td>
</tr>

<tr>
<td> Obtenir les détails d'un échantillon spécifique </td>
<td>

```graphql
query {
  node(id: "gid://irida/Sample/1") {
    ... on Sample {
      id
      name
      description
      metadata
      project {
        id
        fullPath
      }
    }
  }
}
```

</td>
<td>

```json
{
  "data": {
    "node": {
      "id": "gid://irida/Sample/1",
      "name": "Bacillus anthracis/Éclosion 2022 Échantillon 1",
      "description": "Ceci est une description pour l'échantillon Bacillus anthracis/Éclosion 2022 Échantillon 1.",
      "project": {
        "id": "gid://irida/Project/1",
        "fullPath": "bacille/bacille-anthracis/eclosion-2022"
      },
      "metadata": {
        "age": 40,
        "food": "Hamburger au fromage",
        "onset": "2022-06-21",
        "WGS_id": 6862301436,
        "gender": "Féminin",
        "country": "Canada",
        "patient_age": 8,
        "patient_sex": "Masculin",
        "earliest_date": "2022-10-03",
        "NCBI_ACCESSION": "NM_7807606.5"
      }
    }
  }
}
```

</td>
</tr>
</table>

## Authentification avec les jetons d'accès personnels {#authentication-with-personal-access-tokens}

Pour utiliser l'API GraphQL avec [l'un des clients GraphQL](https://graphql.org/code/#graphql-clients), vous devrez générer un jeton d'accès personnel.

### Naviguer vers l'écran Jetons d'accès

Une fois que vous êtes connecté à IRIDA Next, suivez ces étapes.

1. Dans la barre supérieure de la barre latérale gauche, sélectionnez l'**Icône de profil** à côté du signe plus
2. Dans les options du menu déroulant, sélectionnez **Modifier le profil**
3. Dans la barre latérale gauche, sélectionnez **Jetons d'accès**

Cette page vous permet d'ajouter de nouveaux jetons d'accès personnels et de voir/retirer les jetons existants.

### Portées de jeton

Il existe 2 portées pour votre jeton d'accès, `api` et `read_api`

Si vos requêtes GraphQL ne feront que lire des données et ne feront aucun changement, sélectionnez `read_api`.

Si vos requêtes GraphQL modifieront des données ou téléverseront de nouvelles données, sélectionnez `api`.

### Générer un jeton

Lorsque `Créer un jeton d'accès personnel` est cliqué, un jeton secret sera généré pour vous. Celui-ci sera utilisé pour authentifier vos requêtes API GraphQL.

Il est important que vous ne partagiez pas ce jeton avec quelqu'un d'autre car il est directement lié à votre compte.

### Utilisation du jeton pour l'authentification sans session

Les jetons générés par IRIDA Next sont des jetons d'`Authentification de base`. Ils sont liés à votre courriel.

Cela utilise [l'authentification HTTP de base](https://datatracker.ietf.org/doc/html/rfc7617), sous la forme de $USEREMAIL:$ACCESSTOKEN qui est encodé en Base64.

par ex. `user0@email.com:yK1euURqVRtQ1D-3uKsW` devient `dXNlcjBAZW1haWwuY29tOnlLMWV1VVJxVlJ0UTFELTN1S3NX`

Qui serait utilisé comme suit :

par ex. `Authorization: Basic YWRtaW5AZW1haWwuY29tOnlLMWV1VVJxVlJ0UTFELTN1S3NX`

Vous pouvez tester votre jeton en effectuant l'encodage et en exécutant la commande `curl` suivante.

```bash
curl "http://localhost:3000/api/graphql" --header "Authorization: Basic <votre jeton ici>" --header "Content-Type: application/json" --request POST --data "{\"query\": \"query {currentUser{email}}}\"}"
```

réponse

```json
{ "data": { "currentUser": { "email": "user0@email.com" } } }
```

## Authentification avec les jetons Entra ID {#authentication-with-entra-id-bearer-tokens}

Si votre instance IRIDA Next est configurée pour utiliser [Entra ID (Azure AD)](../configuration/authentication.md) pour la connexion,
les intégrations de confiance peuvent authentifier les requêtes de l'API GraphQL en tant qu'utilisateur Entra ID connecté, au lieu d'un
jeton d'accès personnel/compte robot partagé. Ceci est utile pour les intégrations (telles que BDIP) qui créent des échantillons ou
téléversent des fichiers vers IRIDA Next au nom d'utilisateurs déjà connectés au même locataire Entra.

### Fonctionnement

1. L'intégration obtient un jeton d'accès pour l'utilisateur connecté via le
   [flux On-Behalf-Of](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow) d'Entra ID,
   limité à l'inscription d'application de cette instance IRIDA Next (son `client_id`, ou `api_audience` si configuré).
2. L'intégration envoie le jeton d'accès comme jeton porteur (bearer) :

   ```bash
   curl "http://localhost:3000/api/graphql" --header "Authorization: Bearer <votre jeton d'accès ici>" --header "Content-Type: application/json" --request POST --data "{\"query\": \"query {currentUser{email}}}\"}"
   ```

3. IRIDA Next vérifie la signature du jeton (par rapport aux clés de signature publiées par Entra ID), l'émetteur, l'audience,
   l'expiration et le locataire, puis recherche l'utilisateur local correspondant aux revendications `oid`/`tid` du jeton. L'utilisateur
   doit déjà exister dans IRIDA Next (par exemple, en s'étant déjà connecté au moins une fois via le fournisseur entra_id).
4. IRIDA Next vérifie également les portées accordées au jeton (la revendication `scp`). Le jeton **doit** inclure la portée
   `access_as_user`; sinon, l'authentification échoue et la requête est traitée de manière anonyme.
5. Si le jeton est valide, la requête est authentifiée en tant que cet utilisateur, mais reste limitée par les portées `api`/`read_api`
   présentes dans le jeton, exactement comme un jeton d'accès personnel : un jeton avec uniquement `read_api` peut effectuer des
   requêtes mais pas des mutations, et un jeton sans aucune de ces deux portées est authentifié mais ne peut ni interroger ni modifier
   l'API.

### Exigences

- `entra_id` doit être un `omniauth_provider` activé (voir [Connexion à un serveur d'authentification](../configuration/authentication.md)).
- Les informations d'identification `entra_id` (`client_id`, `tenant_id`) doivent être configurées.
- L'utilisateur effectuant l'action doit déjà avoir un compte IRIDA Next lié à son identité Entra ID.
- L'inscription d'application doit exposer une portée `access_as_user` (permission déléguée), et l'intégration doit la demander
  (ainsi que `api` et/ou `read_api`, selon le cas) lors de l'obtention du jeton d'accès via le flux On-Behalf-Of.

Contrairement aux jetons d'accès personnels, les jetons d'accès Entra ID sont de courte durée (généralement ~1 heure), donc les
intégrations utilisant cette méthode sont responsables du rafraîchissement/réémission des jetons selon les besoins.
