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

- **URL** _(Requis)_ du dépôt GitHub du pipeline
- **name** _(Requis)_ du pipeline
- **description** _(Requise)_ du pipeline
- **versions** _(Requises)_ du pipeline qui devraient être disponibles pour le lancement.
  - `name` : _(Requis)_ fait référence au drapeau `-r` utilisé par nextflow.
  - `automatable` : _(Optionnel)_ `true` ou `false` pour spécifier si le pipeline peut être automatisé.
  - `executable` : _(Optionnel)_ `true` ou `false` pour spécifier si le pipeline peut être exécuté. Lorsqu'il est défini sur `false`, le pipeline ne sera pas répertorié à l'utilisateur.
- **overrides** _(Optionnel)_ pour le pipeline
- **samplesheet_overrides** _(Optional)_ pour le pipeline

#### Exemple

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
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
  "some-other/pipeline": {
    ........
  }
}
```

### Remplacements de schéma

La section Remplacements peut être utilisée pour modifier n'importe quoi dans le schéma du pipeline nextflow d'origine. Tout ce qui se trouve dans `"overrides": {<json data>}` remplacera le schéma d'origine par `<json data>` en commençant au niveau le plus élevé.

Dans l'exemple ci-dessous, nous remplacerons les options de connexion à la base de données afin de pouvoir connecter le pipeline à notre chemin de base de données personnalisé. Notez que seuls les champs remplacés doivent être fournis, car tout le reste fourni par le schéma reste le même.

#### Exemple de schéma

```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "Mon schéma d'exemple",
    "description": "Schéma d'exemple : pour démontrer les remplacements",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Options d'entrée/sortie",
            "type": "object",
            "description": "Définir quelles données utiliser avec le pipeline.",
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
                  "description": "Base de données Kraken",
                  "enum": [
                    [
                      "bd_par_defaut",
                      "CHEMIN_VERS_BD"
                    ],
                    [
                      "bd_organisation",
                      "CHEMIN_VERS_BD_ORG"
                    ]
                  ]
                }
            }
        },
        "plus_options": {
          ...
        }
    },
    "plus_options": {
      ...
    }
}
```

#### Exemple de remplacement

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "overrides": {
      "definitions": {
        "input_output_options": {
          "properties": {
            "database": {
              "enum": [
                [
                  "bd_personnalisee",
                  "CHEMIN_VERS_BD_PERSONNALISEE"
                ],
                [
                  "bd_personnalisee_2",
                  "CHEMIN_VERS_BD_PERSONNALISEE_2"
                ]
              ]
            }
          }
        }
      }
    },
    "versions": [...]
  },
  "some-other/pipeline": {
    ........
  }
}
```

#### Résultat effectif

```json
{
    "$schema": "http://example.com/schema",
    "$id": "https://example.com/nextflow_schema.json",
    "title": "Mon schéma d'exemple",
    "description": "Schéma d'exemple : pour démontrer les remplacements",
    "type": "object",
    "definitions": {
        "input_output_options": {
            "title": "Options d'entrée/sortie",
            "type": "object",
            "description": "Définir quelles données utiliser avec le pipeline.",
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
                  "description": "Base de données Kraken",
                  "enum": [
                    [
                      "bd_personnalisee",
                      "CHEMIN_VERS_BD_PERSONNALISEE"
                    ],
                    [
                      "bd_personnalisee_2",
                      "CHEMIN_VERS_BD_PERSONNALISEE_2"
                    ]
                  ]
                }
            }
        },
        "plus_options": {
          ...
        }
    },
    "plus_options": {
      ...
    }
}
```

### Remplacements de la feuille d'échantillons

La section Remplacements de la feuille d'échantillons peut être utilisée pour modifier n'importe quoi dans la samplesheet d'origine du pipeline. Tout ce qui se trouve dans "samplesheet_overrides": {<json data>} écrasera la samplesheet d'origine avec <json data> en commençant au niveau le plus élevé.

Dans l'exemple ci‑dessous, nous remplacerons les champs de métadonnées sélectionnés par défaut. Notez que seuls les champs remplacés doivent être fournis, car tout le reste fourni par la samplesheet par défaut reste le même.

#### Exemple de schéma

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "Mon schéma d'exemple",
  "description": "Schéma d'exemple : pour démontrer les remplacements de la feuille d'échantillons",
  "items": {
        "type": "object",
        "properties": {
            "sample": {
                "type": "string",
                "pattern": "^\\S+$",
                "meta": ["irida_id"],
                "unique": true,
                "errorMessage": "Le nom de l'échantillon doit être fourni et ne peut pas contenir d'espaces."
            },
            "sample_name": {
                "type": "string",
                "meta": ["id"],
                "errorMessage": "Le nom de l’échantillon est facultatif ; s’il est fourni, il remplacera le champ « sample » pour la génération des noms de fichiers et des sorties"
            },
            "mlst_alleles": {
                "type": "string",
                "format": "file-path",
                "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
                "errorMessage": "Le fichier JSON MLST provenant du rapport locidex ne peut pas contenir d'espaces et doit avoir l'extension : '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json' ou '.mlst.subtyping.json.gz'"
            },
            "fastmatch_category": {
                "type": "string",
                "errorMessage": "Doit être « query » ou « reference »",
                "description": "Indique si un échantillon est de type \"query\" ou \"reference\"",
                "fa_icon": "far fa-sticky-note",
                "enum": ["query", "reference"]
            },
            "metadata_1": {
                "type": "string",
                "meta": ["metadata_1"],
                "errorMessage": "Métadonnée associée à l'échantillon (metadata_1).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$"
            },
            "metadata_2": {
                "type": "string",
                "meta": ["metadata_2"],
                "errorMessage": "Métadonnée associée à l'échantillon (metadata_2).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$"
            },
           .........
        },
        "required": ["sample", "mlst_alleles"]
    }
}
```

#### Exemple — remplacement de la samplesheet au niveau de l'entrée du pipeline

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "samplesheet_overrides": {
      "items": {
        "properties": {
            "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
            },
            "metadata_2": {
                "x-irida-next-selected": "prediceted_primary_identification_name"
            },
            .........
        },
        "required": ["sample", "mlst_alleles"]
      }
    },
    "versions": [...]
  },
  "some-other/pipeline": {
    ........
  }
}
```

#### Résultat effectif

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "Mon schéma d'exemple",
  "description": "Schéma d'exemple : pour démontrer les remplacements de la feuille d'échantillons",
  "type": "object",
   "items": {
      "type": "object",
      "properties": {
          "sample": {
              "type": "string",
              "pattern": "^\\S+$",
              "meta": ["irida_id"],
              "unique": true,
              "errorMessage": "Le nom de l'échantillon doit être fourni et ne peut pas contenir d'espaces."
          },
          "sample_name": {
              "type": "string",
              "meta": ["id"],
              "errorMessage": "Le nom de l’échantillon est facultatif ; s’il est fourni, il remplacera le champ « sample » pour la génération des noms de fichiers et des sorties"
          },
          "mlst_alleles": {
              "type": "string",
              "format": "file-path",
              "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
              "errorMessage": "Le fichier JSON MLST provenant du rapport locidex ne peut pas contenir d'espaces et doit avoir l'extension : '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json' ou '.mlst.subtyping.json.gz'"
          },
          "fastmatch_category": {
              "type": "string",
              "errorMessage": "Doit être « query » ou « reference »",
              "description": "Indique si un échantillon est de type \"query\" ou \"reference\"",
              "fa_icon": "far fa-sticky-note",
              "enum": ["query", "reference"]
          },
          "metadata_1": {
              "type": "string",
              "meta": ["metadata_1"],
              "errorMessage": "Métadonnée associée à l'échantillon (metadata_1).",
              "default": "",
              "pattern": "^[^\\n\\t\"]+$",
              "x-irida-next-selected": "new_isolates_date"
          },
          "metadata_2": {
              "type": "string",
              "meta": ["metadata_2"],
              "errorMessage": "Métadonnée associée à l'échantillon (metadata_2).",
              "default": "",
              "pattern": "^[^\\n\\t\"]+$",
              "x-irida-next-selected": "prediceted_primary_identification_name"
          },
         ........
      },
      "required": ["sample", "mlst_alleles"]
    }
}
```

#### Exemple — remplacement de la samplesheet au niveau de la version du pipeline

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "versions": [
      {
        "name": "1.0.3",
        "samplesheet_overrides": {
          "items": {
            "properties": {
              "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
              },
              "metadata_2": {
                "x-irida-next-selected": "prediceted_primary_identification_name"
              },
            .........
            },
            "required": ["sample", "mlst_alleles"]
          }
        }
      },
      ......
    ],
    ........
  },
  "some-other/pipeline": {
    .........
  }
}
```

#### Résultat effectif

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "Mon schéma d'exemple",
  "description": "Schéma d'exemple : pour démontrer les remplacements de la feuille d'échantillons",
  "type": "object",
  "versions": [
    {
      "name": "1.0.3",
      "items": {
        "type": "object",
        "properties": {
            "sample": {
                "type": "string",
                "pattern": "^\\S+$",
                "meta": ["irida_id"],
                "unique": true,
                "errorMessage": "Le nom de l'échantillon doit être fourni et ne peut pas contenir d'espaces."
            },
            "sample_name": {
                "type": "string",
                "meta": ["id"],
                "errorMessage": "Le nom de l’échantillon est facultatif ; s’il est fourni, il remplacera le champ « sample » pour la génération des noms de fichiers et des sorties"
            },
            "mlst_alleles": {
                "type": "string",
                "format": "file-path",
                "pattern": "^\\S+\\.mlst(\\.subtyping)?\\.json(\\.gz)?$",
                "errorMessage": "Le fichier JSON MLST provenant du rapport locidex ne peut pas contenir d'espaces et doit avoir l'extension : '.mlst.json', '.mlst.json.gz', '.mlst.subtyping.json' ou '.mlst.subtyping.json.gz'"
            },
            "fastmatch_category": {
                "type": "string",
                "errorMessage": "Doit être « query » ou « reference »",
                "description": "Indique si un échantillon est de type \"query\" ou \"reference\"",
                "fa_icon": "far fa-sticky-note",
                "enum": ["query", "reference"]
            },
            "metadata_1": {
                "type": "string",
                "meta": ["metadata_1"],
                "errorMessage": "Métadonnée associée à l'échantillon (metadata_1).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$",
                "x-irida-next-selected": "new_isolates_date"
            },
            "metadata_2": {
                "type": "string",
                "meta": ["metadata_2"],
                "errorMessage": "Métadonnée associée à l'échantillon (metadata_2).",
                "default": "",
                "pattern": "^[^\\n\\t\"]+$",
                "x-irida-next-selected": "prediceted_primary_identification_name"
            },
          ........
        },
        "required": ["sample", "mlst_alleles"]
      },
      ..........
    }
  ]
}
```
