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
  samples (first:5){
    nodes{
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
          "name": "Bacillus anthracis/Outbreak 2022 Sample 1",
          "id": "gid://irida/Sample/1"
        },
        {
          "name": "Bacillus anthracis/Outbreak 2022 Sample 2",
          "id": "gid://irida/Sample/2"
        },
        {
          "name": "Bacillus anthracis/Outbreak 2022 Sample 3",
          "id": "gid://irida/Sample/3"
        },
        {
          "name": "Bacillus anthracis/Outbreak 2022 Sample 4",
          "id": "gid://irida/Sample/4"
        },
        {
          "name": "Bacillus anthracis/Outbreak 2022 Sample 5",
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
  node(id: "gid://irida/Sample/1"){
    ... on Sample{
      id,
      name
      description
      metadata
      project{
        id,
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
      "name": "Bacillus anthracis/Outbreak 2022 Sample 1",
      "description": "This is a description for sample Bacillus anthracis/Outbreak 2022 Sample 1.",
      "project": {
        "id": "gid://irida/Project/1",
        "fullPath": "bacillus/bacillus-anthracis/outbreak-2022"
      },
      "metadata": {
        "age": 40,
        "food": "Cheeseburger",
        "onset": "2022-06-21",
        "WGS_id": 6862301436,
        "gender": "Female",
        "country": "Gabon",
        "patient_age": 8,
        "patient_sex": "Male",
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

## Authentification avec les jetons d'accès personnels

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
curl "http://localhost:3000/api/graphql" --header "Authorization: Basic <your token here>" --header "Content-Type: application/json" --request POST --data "{\"query\": \"query {currentUser{email}}}\"}"
```

réponse

```json
{"data":{"currentUser":{"email":"user0@email.com"}}}
```
