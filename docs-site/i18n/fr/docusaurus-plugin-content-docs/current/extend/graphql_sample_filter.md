---
sidebar_position: 3
id: graphql_sample_filter
title: Filtre d'échantillon GraphQL
---

## Aperçu

Le filtrage d'échantillons peut être effectué en utilisant l'une ou les deux des méthodes suivantes :

- _Recherche de base_ interroge les échantillons avec un nom ou un puid contenant une chaîne donnée
- _Recherche avancée_ utilise des groupes et des conditions pour construire des requêtes complexes données les métadonnées d'échantillon

Un exemple de requête GraphQL.

```graphql
query {
  samples(
    orderBy: { field: name, direction: desc }
    filter: {
      name_or_puid_cont: "Nom d'échantillon"
      advanced_search: [
        [
          { field: "metadata.country", operator: EQUALS, value: "Canada" }
          {
            field: "metadata.collection_date"
            operator: GREATER_THAN_EQUALS
            value: "2024-01-01"
          }
          {
            field: "metadata.collection_date"
            operator: LESS_THAN_EQUALS
            value: "2024-12-31"
          }
        ]
        [
          {
            field: "metadata.outbreak_code"
            operator: IN
            value: ["2406MLGX6-1", "2406MLGX6-2"]
          }
        ]
      ]
    }
  ) {
    nodes {
      name
      description
      id
      puid
      createdAt
      metadata
    }
    totalCount
  }
}
```

## Recherche avancée

La recherche avancée utilise des groupes et des conditions pour construire des requêtes complexes basées sur des critères. Une recherche avancée se compose d'un ou plusieurs groupes et chaque groupe se compose d'une ou plusieurs conditions. Les groupes sont joints ensemble avec un opérateur logique OR et les conditions sont jointes avec un opérateur logique AND. Par exemple, en supposant que A, B, C et D sont des conditions pour une recherche avancée [[A,B],[C,D]] se traduirait par (A AND B) OR (C AND D).

### Définitions

**Groupes** se composent d'une ou plusieurs conditions.

**Conditions** se composent d'un champ, d'un opérateur et d'une valeur.

**Champs** sont des attributs d'échantillon qui peuvent être l'un de name, puid, created_at, updated_at ou attachments_updated_at. Si le champ est metadata, il doit commencer par 'metadata.'.

**Opérateurs** ne peuvent être que l'un de EQUALS, NOT_EQUALS, LESS_THAN_EQUALS, GREATER_THAN_EQUALS, CONTAINS, EXISTS, NOT_EXISTS, IN et NOT_IN.

**Valeurs** sont toujours des chaînes et sont insensibles à la casse. Une valeur peut également être un tableau de chaînes si elle est utilisée avec les opérateurs IN ou NOT_IN. Les valeurs ne sont pas requises lorsqu'elles sont utilisées avec EXISTS ou NOT_EXISTS.

### Validation

L'entrée de recherche avancée est validée avant que la recherche ne soit effectuée. Voici une liste des règles de validation.

1. Les valeurs de date doivent être formatées « AAAA-MM-JJ » et le champ doit se terminer par '\_date'.

2. Les conditions doivent avoir des champs uniques au sein du même groupe sauf si elles utilisent les opérateurs between. Les opérateurs between sont LESS_THAN_EQUAL et GREATER_THAN_EQUALS.

Les règles de validation mentionnées ci-dessus concernant les opérateurs ont été résumées dans ce tableau pour référence rapide.

| Opérateur           | Valeur             | Unicité                                           |
| ------------------- | ------------------ | ------------------------------------------------- |
| EQUALS              | Chaîne             | Ne peut pas être combiné avec d'autres opérateurs |
| NOT_EQUALS          | Chaîne             | Ne peut pas être combiné avec d'autres opérateurs |
| LESS_THAN_EQUALS    | Date ou numérique  | Peut être combiné avec GREATER_THAN_EQUALS        |
| GREATER_THAN_EQUALS | Date ou numérique  | Peut être combiné avec LESS_THAN_EQUALS           |
| CONTAINS            | Chaîne             | Ne peut pas être combiné avec d'autres opérateurs |
| EXISTS              | N/A                | Ne peut pas être combiné avec d'autres opérateurs |
| NOT_EXISTS          | N/A                | Ne peut pas être combiné avec d'autres opérateurs |
| IN                  | Tableau de chaînes | Ne peut pas être combiné avec d'autres opérateurs |
| NOT_IN              | Tableau de chaînes | Ne peut pas être combiné avec d'autres opérateurs |

_\* La colonne d'unicité compare les conditions au sein du même groupe._

Les messages d'erreur seront préfixés avec l'index du groupe, l'index de la condition et l'attribut de condition (champ, opérateur ou valeur)
pour faciliter la compréhension de l'argument de filtre qui a causé un échec.
Un exemple de message d'erreur est `filter.advanced_search.0.0.field: 'metadata.' is an invalid metadata field`.
