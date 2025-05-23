---
sidebar_position: 5
id: storage
title: Storage Options
---

## Storage

When configuring storage, a mix of credentials and ENV variables are used

You can edit your credentials file with the following command.

`EDITOR="vim --nofork" bin/rails credentials:edit --environment production`

When selecting a storage service to use, set the following ENV variable to the service you want.

| ENV variable | Description | Default |
| -------- | ------- | ------- |
| `RAILS_STORAGE_SERVICE` | Which type of storage to use. One of [`local`,`amazon`,`google`,`microsoft`]. | `local` |

Default values below that contain `#{Rails.env}` refer to the environment the IRIDA Next is running in. In production, this is `production`

### Local

Files are stored locally in the `storage/` directory.

No additional options are needed for this configuration.

### Amazon S3

Credentials

```yml
aws:
  access_key_id:
  secret_access_key:
```

| ENV variable | Description | Default |
| -------- | ------- | ------- |
| `S3_REGION` | S3 region | `us-east-1` |
| `S3_BUCKET_NAME` | S3 bucket name | `your_own_bucket-#{Rails.env}` |

### Google Cloud Storage

| ENV variable | Description | Default |
| -------- | ------- | ------- |
| `GCS_PROJECT_NAME` | Google Cloud Storage project name | `your_project` |
| `GCS_KEYFILE` | Relative path to gcs.keyfile | `gcs.keyfile` |
| `GCS_BUCKET_NAME` | Google Cloud Storage bucket name | `your_own_bucket-#{Rails.env}` |

### Microsoft Azure

Credentials

```yml
azure_storage:
  storage_access_key:
```

| ENV variable | Description | Default |
| -------- | ------- | ------- |
| `AZURE_STORAGE_ACCOUNT_NAME` | Storage Account Name | `your_account_name` |
| `AZURE_STORAGE_CONTAINER_NAME` | Storage Container Name | `your_container_name-#{Rails.env}` |
| `AZURE_STORAGE_BLOB_HOST` | Optional. Storage Blob Host | N/A |
