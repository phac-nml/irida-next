---
sidebar_position: 5
id: storage
title: Options de stockage
---

## Stockage

Lors de la configuration du stockage, un mélange d'informations d'identification et de variables ENV est utilisé

Vous pouvez modifier votre fichier d'informations d'identification avec la commande suivante.

`EDITOR="vim --nofork" bin/rails credentials:edit --environment production`

Lors de la sélection d'un service de stockage à utiliser, définissez la variable ENV suivante sur le service que vous souhaitez.

| Variable d'environnement | Description                                                                      | Défaut  |
| :----------------------- | :------------------------------------------------------------------------------- | :------ |
| `RAILS_STORAGE_SERVICE`  | Quel type de stockage utiliser. L'un de [`local`,`amazon`,`google`,`microsoft`]. | `local` |

Les valeurs par défaut ci-dessous contenant `#{Rails.env}` font référence à l'environnement dans lequel IRIDA Next s'exécute. En production, c'est `production`

### Local

Les fichiers sont stockés localement dans le répertoire `storage/`.

Aucune option supplémentaire n'est nécessaire pour cette configuration.

### Amazon S3

Informations d'identification

```yml
aws:
  access_key_id:
  secret_access_key:
```

| Variable d'environnement | Description            | Défaut                                   |
| :----------------------- | :--------------------- | :--------------------------------------- |
| `S3_REGION`              | Région S3              | `us-east-1`                              |
| `S3_BUCKET_NAME`         | Nom du compartiment S3 | `votre_propre_compartiment-#{Rails.env}` |

### Google Cloud Storage

| Variable d'environnement | Description                              | Défaut                                   |
| :----------------------- | :--------------------------------------- | :--------------------------------------- |
| `GCS_PROJECT_NAME`       | Nom du projet Google Cloud Storage       | `votre_projet`                           |
| `GCS_KEYFILE`            | Chemin relatif vers gcs.keyfile          | `gcs.keyfile`                            |
| `GCS_BUCKET_NAME`        | Nom du compartiment Google Cloud Storage | `votre_propre_compartiment-#{Rails.env}` |

### Microsoft Azure

Informations d'identification

```yml
azure_storage:
  storage_access_key:
```

| Variable d'environnement       | Description                      | Défaut                             |
| :----------------------------- | :------------------------------- | :--------------------------------- |
| `AZURE_STORAGE_ACCOUNT_NAME`   | Nom du compte de stockage        | `votre_nom_compte`                 |
| `AZURE_STORAGE_CONTAINER_NAME` | Nom du conteneur de stockage     | `votre_nom_conteneur-#{Rails.env}` |
| `AZURE_STORAGE_BLOB_HOST`      | Optionnel. Hôte Blob de stockage | N/A                                |
