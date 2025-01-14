---
sidebar_position: 6
id: options
title: Advanced Configuration Options
---

## ENV variables

### IRIDA Next Environment

Primary ENV Variable which sets what type of environment to run

| ENV variable | Description                                   | Default       |
| ------------ | --------------------------------------------- | ------------- |
| `RAILS_ENV`  | One of [`production`, `development`, `test`]. | `development` |

### Additional Options

| ENV variable                 | Description                                                                                              | Default                    |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------- |
| `RAILS_MAX_THREADS`          | Number of threads in the thread pool                                                                     | `5`                        |
| `RAILS_HOST`                 | URL host for the application                                                                             | `example.com`              |
| `RAILS_PORT`                 | Port that the application runs on                                                                        | `3000` *when `RAILS_ENV` is `development`* |
| `RAILS_PROTOCOL`             | Protocol the application uses                                                                            | `http`                     |
| `RAILS_DAILY_LOG_ROTATION`   | Rotate the logs daily. For production environment only.                                                  | `false`                    |
| `RAILS_LOG_TO_STDOUT`        | Enable logging to stdout                                                                                 | `false`                    |
| `REDIS_URL`                  | Set the Redis URL                                                                                        | `redis://localhost:6379/1` |
| `DATABASE_URL`               | Set the URL for the postgres database                                                                    | `nil`                      |
| `JOBS_DATABASE_URL`          | Set the URL for the postgres jobs database                                                               | `nil`                      |
| `PORT`                       | Set the port that Puma listens on to receive requests                                                    | `3000`                     |
| `PIDFILE`                    | Set the pidfile that Puma will use                                                                       | `tmp/pids/server.pid`      |
| `RAILS_SERVE_STATIC_FILES`   | Set to enable serving static files from `/public` folder. By default this is handled by Apache or NGINX. | `false`                    |
| `PUID_APP_PREFIX`            | Set the persistent unique ID prefix                                                                      | `INXT`                     |
| `SEED_ATTACHMENT_PER_SAMPLE` | Set number of attachments per sample when seeding the database with test data                            | `2`                        |
| `ENABLE_CRON`                | Enables built in cron cleanup jobs for samples, attachments, and data exports.                           | `true`                     |
| `CRON_CLEANUP_AFTER_DAYS`    | Set the number of days old a deleted sample/attachment must be before it is cleaned.                     | `7`                        |
| `RAILS_ENABLE_WEB_CONSOLE`    | Development mode only: When set, a rails console will be present on every webpage.                      | `nil`                        |
