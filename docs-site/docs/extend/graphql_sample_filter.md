---
sidebar_position: 3
id: graphql_sample_filter
title: GraphQL Sample Filter
---

## Overview

Sample filtering can be performed using one or both of the following ways:

- _Basic search_ queries samples with a name or puid containing a given string
- _Advanced search_ uses groups & conditions to build complex queries given sample metadata

An example of a GraphQL query.

```graphql
query {
  samples(
    orderBy: { field: name, direction: desc }
    filter: {
      name_or_puid_cont: "Sample Name"
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

## Advanced Search

Advanced search uses groups & conditions to build complex queries based on criteria. An advanced search consists of one or more groups and each group consists of one or more conditions. Groups are joined together with a logical OR operator and conditions are joined with a logical AND operator. For example, assuming A, B, C, and D are conditions for an advanced search [[A,B],[C,D]] would translate to (A AND B) OR (C AND D).

### Definitions

**Groups** consist of one or more conditions.

**Conditions** consist of a field, operator, and value.

**Fields** are sample attributes which can be one of name, puid, created_at, updated_at, or attachments_updated_at. If the field is metadata, it must begin with 'metadata.'.

**Operators** can only be one of EQUALS, NOT_EQUALS, LESS_THAN_EQUALS, GREATER_THAN_EQUALS, CONTAINS, EXISTS, NOT_EXISTS, IN, and NOT_IN.

**Values** are always strings and are case insensitive. A value can also be an array of strings if used with the IN or NOT_IN operators. Values are not required when used withe EXISTS or NOT_EXISTS.

### Validation

The advanced search input is validated before the search is performed. This is a list of the validation rules.

1. Date values must be formatted "YYYY-MM-DD" and the field must end with '\_date'.

2. Conditions must have unique fields within the same group unless using the between operators. Between operators are LESS_THAN_EQUAL and GREATER_THAN_EQUALS.

Validation rules mentioned above around operators have been summarized in this table for quick reference.

| Operator            | Value            | Uniqueness                               |
| ------------------- | ---------------- | ---------------------------------------- |
| EQUALS              | String           | Cannot be combined with other operators  |
| NOT_EQUALS          | String           | Cannot be combined with other operators  |
| LESS_THAN_EQUALS    | Date or numeric  | Can be combined with GREATER_THAN_EQUALS |
| GREATER_THAN_EQUALS | Date or numeric  | Can be combined with LESS_THAN_EQUALS    |
| CONTAINS            | String           | Cannot be combined with other operators  |
| EXISTS              | N/A              | Cannot be combined with other operators  |
| NOT_EXISTS          | N/A              | Cannot be combined with other operators  |
| IN                  | Array of strings | Cannot be combined with other operators  |
| NOT_IN              | Array of strings | Cannot be combined with other operators  |

_\* The uniqueness column compares conditions within the same group._

Error messages will be prefixed with the group index, condition index, and condition attribute (field, operator, or value)
to make it easier to understand which filter argument caused a failure.
An example error message example is `filter.advanced_search.0.0.field: 'metadata.' is an invalid metadata field`.
