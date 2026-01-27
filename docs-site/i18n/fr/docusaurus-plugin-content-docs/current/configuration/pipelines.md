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
- **samplesheet_schema_overrides** _(Optional)_ pour le pipeline
- **settings**
  - `min_samples` : _(Optionnel)_ `number` pour spécifier le nombre minimal d'échantillons requis pour l'analyse par le pipeline
  - `max_samples`: _(Optionnel)_ `nombre` pour spécifier le nombre maximum d'échantillons pouvant être analysés par le pipeline. Si une valeur de -1 est définie, cela indique l'absence de maximum, ce qui désactive efficacement ce paramètre
  - `min_runtime` : _(Optionnel)_ `number` ou `string (formula)` pour spécifier le temps d'exécution minimal autorisé (en secondes) pour le pipeline
  - `max_runtime` : _(Optionnel)_ `number` ou `string (formula)` pour spécifier le temps d'exécution maximal autorisé (en secondes) pour le pipeline
  - `status_check_interval` : _(Optionnel)_ `number` spécifiant l'intervalle (en secondes) entre les vérifications d'état envoyées au WES. Par défaut : `30` secondes.
  - `estimated_cost_formula` : _(Optionnel)_ `string (formula)` spécifiant le coût estimé (en dollars) pour l'analyse

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

#### Exemple de pipeline Nextflow basé sur json-schema http://json-schema.org/draft-07/schema

Lors du remplacement d’un pipeline Nextflow basé sur json-schema http://json-schema.org/draft-07/schema, il faut utiliser `definitions` comme première clé imbriquée sous `overrides`.

##### Schéma

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "$id": "https://raw.githubusercontent.com/phac-nml/iridanextexample/main/nextflow_schema.jsonn",
  "title": "phac-nml/iridanextexample pipeline parameters",
  "description": "IRIDA Next Example Pipeline",
  "type": "object",
  "definitions": {
    "input_output_options": {
      "title": "Input/Output Options",
      "type": "object",
      "fa_icon": "fas fa-terminal",
      "description": "Define where the pipeline should find input data and save output data.",
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
    ...
  },
  ...
}
```

##### Remplacement

```json
{
  "phac-nml/iridanextexample": {
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
    ...
  }
}
```

##### Résultat effectif

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "$id": "https://raw.githubusercontent.com/phac-nml/iridanextexample/main/nextflow_schema.json",
  "title": "phac-nml/iridanextexample pipeline parameters",
  "description": "IRIDA Next Example Pipeline",
  "type": "object",
  "definitions": {
    "input_output_options": {
      "title": "Input/Output Options",
      "type": "object",
      "fa_icon": "fas fa-terminal",
      "description": "Define where the pipeline should find input data and save output data.",
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

#### Exemple de pipeline Nextflow basé sur json-schema https://json-schema.org/draft/2020-12/schema

Lors du remplacement d’un pipeline Nextflow basé sur json-schema https://json-schema.org/draft/2020-12/schema, il faut utiliser `$defs` comme première clé imbriquée sous `overrides`.

##### Schéma

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://raw.githubusercontent.com/phac-nml/iridanextexample2/main/nextflow_schema.json",
  "title": "phac-nml/iridanextexample2 pipeline parameters",
  "description": "An example pipeline for running on IRIDA-Next with nf-schema",
  "type": "object",
  "$defs": {
    "input_output_options": {
      "title": "Input/output options",
      "type": "object",
      "fa_icon": "fas fa-terminal",
      "description": "Define where the pipeline should find input data and save output data.",
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
    ...
  },
  ...
}
```

#### Remplacement

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample2",
    "name": "phac-nml/iridanextexample2",
    "description": "IRIDA Next Example 2 Pipeline",
    "overrides": {
      "$def": {
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
    ...
  }
}
```

#### Résultat effectif

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://raw.githubusercontent.com/phac-nml/iridanextexample2/main/nextflow_schema.json",
  "title": "phac-nml/iridanextexample2 pipeline parameters",
  "description": "An example pipeline for running on IRIDA-Next with nf-schema",
  "type": "object",
  "$defs": {
    "input_output_options": {
      "title": "Input/output options",
      "type": "object",
      "fa_icon": "fas fa-terminal",
      "description": "Define where the pipeline should find input data and save output data.",
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

### Remplacements du schéma de la feuille d'échantillons

La section des remplacements de schéma de la feuille d'échantillons peut être utilisée pour modifier n'importe quel élément du schéma de feuille d'échantillons d'origine. Tout ce qui se trouve dans `"samplesheet_schema_overrides": {<json data>}` remplacera la feuille d'échantillons d'origine par `<json data>` en commençant par le niveau le plus élevé.

Dans l'exemple ci‑dessous, nous remplacerons les champs de métadonnées sélectionnés par défaut. Notez que seuls les champs remplacés doivent être fournis, car tout le reste fourni par la samplesheet par défaut reste le même.

#### Exemple de schéma

```json
{
  "$schema": "http://example.com/schema",
  "$id": "https://example.com/nextflow_schema.json",
  "title": "Mon schéma d'exemple",
  "description": "Schéma d'exemple : pour démontrer les remplacements de schéma de feuilles d'échantillons",
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

#### Exemple de remplacement de schéma de feuilles d'échantillons au niveau de l'entrée du pipeline

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "samplesheet_schema_overrides": {
      "items": {
        "properties": {
            "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
            },
            "metadata_2": {
                "x-irida-next-selected": "predicted_primary_identification_name"
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
  "description": "Schéma d'exemple : pour démontrer les remplacements de schéma de feuilles d'échantillons",
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
              "x-irida-next-selected": "predicted_primary_identification_name"
          },
         ........
      },
      "required": ["sample", "mlst_alleles"]
    }
}
```

#### Exemple de remplacement de schéma de feuilles d'échantillons au niveau de la version du pipeline

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "versions": [
      {
        "name": "1.0.3",
        "samplesheet_schema_overrides": {
          "items": {
            "properties": {
              "metadata_1": {
                "x-irida-next-selected": "new_isolates_date"
              },
              "metadata_2": {
                "x-irida-next-selected": "predicted_primary_identification_name"
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
  "description": "Schéma d'exemple : pour démontrer les remplacements de schéma de feuilles d'échantillons",
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
                "x-irida-next-selected": "predicted_primary_identification_name"
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

### Paramètres du pipeline

La section Paramètres permet de définir des paramètres spécifiques au pipeline au niveau de l'entrée et/ou de la version.

Dans l'exemple ci‑dessous, nous définissons les paramètres spécifiques au pipeline au niveau de l'entrée :

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "settings": {
      "min_samples": 1,
      "max_samples": 100,
      "min_runtime": 60,
      "max_runtime": 600,
      "status_check_interval": 60,
      "estimated_cost_formula": "5 + SAMPLE_COUNT * 1.35"
    },
    "versions": [
      {
        "name": "1.0.3"
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

Dans l'exemple ci‑dessous, nous définissons les paramètres spécifiques au pipeline au niveau de la version :

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "versions": [
      {
        "name": "1.0.3",
        "settings": {
          "min_samples": 1,
          "max_samples": 100,
          "min_runtime": 60,
          "max_runtime": 600,
          "status_check_interval": 60,
          "estimated_cost_formula": "5 + SAMPLE_COUNT * 1.35"
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

Dans l'exemple ci‑dessous, nous définissons les paramètres spécifiques au pipeline au niveau de l'entrée et de la version. Les paramètres au niveau de la version n'ont à être définis que pour ceux qui diffèrent des paramètres de l'entrée.

```json
{
  "phac-nml/iridanextexample": {
    "url": "https://github.com/phac-nml/iridanextexample",
    "name": "phac-nml/iridanextexample",
    "description": "Pipeline d'exemple IRIDA Next",
    "settings": {
      "min_samples": 1,
      "max_samples": 100,
      "min_runtime": 60,
      "max_runtime": 600,
      "status_check_interval": 60,
      "estimated_cost_formula": "5 + SAMPLE_COUNT * 1.35"
    },
    "versions": [
      {
        "name": "1.0.3",
        "settings": {
          "max_samples": 500,
          "status_check_interval": 45,
          "estimated_cost_formula": "5 + SAMPLE_COUNT * 1.35"
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
