---
sidebar_position: 2
id: graphql_workflow_submission
title: Tutoriel de soumission de flux de travail GraphQL
---

### Veuillez noter :

Ceci est une fonctionnalité avancée. Veuillez vous familiariser avec la [Documentation de l'API GraphQL](./graphql) avant de continuer avec ce tutoriel.

## Aperçu

La soumission d'une exécution de flux de travail via l'API GraphQL se fait en plusieurs étapes. Il est prévu que cela soit fait par programme et non manuellement. De nombreux identifiants seront récupérés et utilisés dans le processus de soumission, donc simplement copier et coller les valeurs entraînera probablement une erreur de l'utilisateur.

Étapes :

1. Interroger les pipelines
2. Interroger des informations spécifiques sur le pipeline
3. Interroger les informations du projet
4. Interroger les données d'échantillon et de fichier du projet
5. Soumettre une exécution de flux de travail en utilisant les informations interrogées dans les étapes précédentes

Veuillez noter : Toutes les valeurs récupérées en exécutant ces requêtes sont uniques à votre base de données. Copier et coller les commandes sans remplacer les valeurs par vos propres identifiants ne fonctionnera pas.

### 1. Interroger les pipelines

Interroger la liste des pipelines pour trouver celui que vous souhaitez utiliser.

```graphql
query getPipelines {
  pipelines(workflowType: "available") {
    name
    version
  }
}
```

Résultat

```json
{
  "data": {
    "pipelines": [
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.3"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.2"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.1"
      },
      {
        "name": "phac-nml/iridanextexample",
        "version": "1.0.0"
      }
    ]
  }
}
```

Les champs `name` et `version` seront utilisés dans la prochaine étape. Dans cet exemple, la version `1.0.3`.

### 2. Interroger les informations sur le pipeline

Nous sommes capables d'obtenir toutes les informations sur un pipeline avec cette requête.

```graphql
query getPipelineInfo {
  pipeline(
    workflowName: "phac-nml/iridanextexample"
    workflowVersion: "1.0.3"
  ) {
    automatable
    description
    executable
    metadata
    name
    version
    workflowParams
  }
}
```

Résultat : (tronqué pour la brièveté - voir fichier d'origine pour le résultat complet)

La sortie nous informe de la structure des champs que nous fournirons pour exécuter le pipeline.

Spécifiquement, nous utiliserons les champs suivants du résultat :

- `workflowName`
- `workflowVersion`
- `workflowParams`
  - `assembler`
  - `random_seed`
  - `project_name`

La sortie nous informe également de la structure pour `samplesWorkflowExecutionAttributes` (`sample_id`) et `samplesheet_params` (`sample`, `fastq_1`, `fastq_2`) dans notre requête de soumission finale.

### 3. Interroger les informations sur le projet

Interroger pour trouver le projet contenant les échantillons que vous souhaitez utiliser dans le pipeline. Dans cet exemple, nous obtenons simplement le premier projet.

```graphql
query getProjects {
  projects(first: 1) {
    nodes {
      fullName
      id
      fullPath
    }
  }
}
```

Résultat

```json
{
  "data": {
    "projects": {
      "nodes": [
        {
          "fullName": "Borrelia / Borrelia burgdorferi / Outbreak 2024",
          "id": "gid://irida/Project/2bd03791-2213-444d-8df3-fdda40fc262a",
          "fullPath": "borrelia/borrelia-burgdorferi/outbreak-2024"
        }
      ]
    }
  }
}
```

Nous utiliserons le champ `fullPath` dans la prochaine étape, et `id` dans l'étape finale

### 4. Interroger les données d'échantillon et de fichier du projet

En utilisant le `fullPath` de l'étape précédente, nous interrogerons les informations d'échantillon et de fichier que nous utiliserons dans le pipeline.

L'étape 2 nous a informés que pour chaque échantillon nous avons besoin de :

- l'`id` de l'échantillon
- le `puid` de l'échantillon,
- les `id` des fichiers (pièce jointe)

Dans cet exemple, nous n'utiliserons qu'1 échantillon.

```graphql
query getProjectInfo {
  project(fullPath: "borrelia/borrelia-burgdorferi/outbreak-2024") {
    samples(first: 1) {
      nodes {
        id
        puid
        attachments {
          nodes {
            filename
            id
          }
        }
      }
    }
  }
}
```

Résultat (tronqué)

Dans notre exemple, nous nous intéressons aux lectures avant et arrière, noms de fichiers `08-55...R1...fastq.gz` et `08-55...R2...fastq.gz`. Faites attention de noter quel identifiant de fichier est avant et arrière car l'étape suivante les acceptera comme `fastq_1` et `fastq_2`. Les directions de lecture peuvent également être interrogées à partir des champs `metadata` des `attachments`.

### 5. Soumettre une exécution de flux de travail en utilisant les informations interrogées dans les étapes précédentes

En utilisant toutes les informations recueillies dans les étapes précédentes, nous pouvons maintenant soumettre notre exécution de flux de travail.

Puisqu'il s'agit d'une mutation, nous incluons également les blocs `workflowExecution` et `error` pour voir si notre soumission a réussi.

```graphql
mutation submitWorkflowExecution {
  submitWorkflowExecution(
    input: {
      name: "Ma soumission de flux de travail depuis GraphQL"
      projectId: "gid://irida/Project/2bd03791-2213-444d-8df3-fdda40fc262a"
      updateSamples: false
      emailNotification: false
      workflowName: "phac-nml/iridanextexample"
      workflowVersion: "1.0.3"
      workflowParams: {
        assembler: "stub"
        random_seed: 1
        project_name: "assembly"
      }
      samplesWorkflowExecutionsAttributes: [
        {
          sample_id: "gid://irida/Sample/c9f3806d-4bf1-4462-bc46-7b547338cc11"
          samplesheet_params: {
            sample: "INXT_SAM_AZCMYRDHEJ"
            fastq_1: "gid://irida/Attachment/f2fad21f-f68f-4871-990f-b47880bed390"
            fastq_2: "gid://irida/Attachment/cad0ae33-0c82-4960-8580-92358686609f"
          }
        }
      ]
    }
  ) {
    workflowExecution {
      name
      state
      id
    }
    errors {
      message
      path
    }
  }
}
```

Résultat

```json
{
  "data": {
    "submitWorkflowExecution": {
      "workflowExecution": {
        "name": "Ma soumission de flux de travail depuis GraphQL",
        "state": "initial",
        "id": "gid://irida/WorkflowExecution/468dcdb5-cf94-4deb-b0b6-67033f156af4"
      },
      "errors": []
    }
  }
}
```

Si nous regardons maintenant la page Exécutions de flux de travail dans IRIDA Next, nous devrions voir notre pipeline soumis.
