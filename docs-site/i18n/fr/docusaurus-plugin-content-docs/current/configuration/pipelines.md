---
sidebar_position: 3
id: pipelines
title: Enregistrement des pipelines
---

Les pipelines sont enregistrés au démarrage du serveur IRIDA Next. Les redémarrages futurs du serveur n'enregistreront que les nouveaux pipelines ajoutés au fichier de configuration, et les fichiers de schéma pour un pipeline particulier seront mis à jour si des versions plus récentes sont disponibles dans le dépôt.

## Dépôt de pipeline

Actuellement, seuls les pipelines **Nextflow** sont pris en charge et ils doivent avoir un dépôt GitHub. Chaque pipeline doit avoir un fichier `nextflow_schema.json` au niveau supérieur du dépôt, et un fichier `schema_input.json` sous un répertoire `assets` dans le dépôt.

## Configuration

### Configuration

Le fichier de configuration pour enregistrer les pipelines est au format `json` et stocké dans le répertoire `config/pipelines/` avec le nom `pipelines.json`.

Ce fichier `pipelines.json` devrait être au format ci-dessous et peut inclure les éléments suivants :

- **URL** *(Requis)* du dépôt GitHub du pipeline
- **name** *(Requis)* du pipeline
- **description** *(Requise)* du pipeline
- **versions** *(Requises)* du pipeline qui devraient être disponibles pour le lancement.
  - `name` : *(Requis)* fait référence au drapeau `-r` utilisé par nextflow.
  - `automatable` : *(Optionnel)* `true` ou `false` pour spécifier si le pipeline peut être automatisé.
  - `executable` : *(Optionnel)* `true` ou `false` pour spécifier si le pipeline peut être exécuté. Lorsqu'il est défini sur `false`, le pipeline ne sera pas répertorié à l'utilisateur.
- **overrides** *(Optionnel)* pour le pipeline

#### Exemple

```json
[
  {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "overrides": {
      # VOIR SECTION OVERRIDE CI-DESSOUS
    },
    "versions": [
      {
        "name": "1.0.2",
        "automatable": true,
        "executable": true
      },
      {
        "name": "1.0.1",
        "automatable": true,
        "executable": false
      },
      {
        "name": "1.0.0",
        "automatable": false,
        "executable": true
      }
    ]
  },
  {
    ........
  }
]
```

### Remplacements de schéma

La section Remplacements peut être utilisée pour modifier n'importe quoi dans le schéma du pipeline nextflow d'origine. Tout ce qui se trouve dans `"overrides": {<json data>}` remplacera le schéma d'origine par `<json data>` en commençant au niveau le plus élevé.

Dans l'exemple ci-dessous, nous remplacerons les options de connexion à la base de données afin de pouvoir connecter le pipeline à notre chemin de base de données personnalisé. Notez que seuls les champs remplacés doivent être fournis, car tout le reste fourni par le schéma reste le même.

#### Exemple de schéma

```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "My Example Schema",
    "description": "Example Schema: for demonstrating overrides",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Input/Output Options",
            "type": "object",
            "description": "Define which data to use with the pipeline.",
            "required": ["input", "outdir"],
            "properties": {
                "input": {
                    ...
                },
                "outdir": {
                    ...
                },
                "database": {
                  "type": "string",
                  "description": "Kraken DB",
                  "enum": [
                    [
                      "default_db",
                      "PATH_TO_DB"
                    ],
                    [
                      "organization db",
                      "PATH_TO_ORG_DB"
                    ]
                  ]
                }
            }
        },
        "more options": {
          ...
        }
    },
    "more options": {
      ...
    }
}
```

#### Exemple de remplacement

```json
[
  {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "IRIDA Next Example Pipeline",
    "overrides": {
      "definitions": {
        "input_output_options": {
          "properties": {
            "database": {
              "enum": [
                [
                  "custom_db",
                  "PATH_TO_CUSTOM_DB"
                ],
                [
                  "custom_db_2",
                  "PATH_TO_CUSTOM_DB_2"
                ]
              ]
            }
          }
        }
      }
    },
    "versions": [...]
  },
  {
    ........
  }
]
```

#### Résultat effectif

```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "My Example Schema",
    "description": "Example Schema: for demonstrating overrides",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Input/Output Options",
            "type": "object",
            "description": "Define which data to use with the pipeline.",
            "required": ["input", "outdir"],
            "properties": {
                "input": {
                    ...
                },
                "outdir": {
                    ...
                },
                "database": {
                  "type": "string",
                  "description": "Kraken DB",
                  "enum": [
                    [
                      "custom_db",
                      "PATH_TO_CUSTOM_DB"
                    ],
                    [
                      "custom_db_2",
                      "PATH_TO_CUSTOM_DB_2"
                    ]
                  ]
                }
            }
        },
        "more options": {
          ...
        }
    },
    "more options": {
      ...
    }
}
```
