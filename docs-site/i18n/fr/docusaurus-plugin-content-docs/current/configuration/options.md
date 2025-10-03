---
sidebar_position: 6
id: options
title: Options de configuration avancées
---

## Variables ENV

### Environnement IRIDA Next

Variable ENV principale qui définit le type d'environnement à exécuter

| Variable ENV | Description                                   | Défaut        |
| ------------ | --------------------------------------------- | ------------- |
| `RAILS_ENV`  | L'un de [`production`, `development`, `test`]. | `development` |

### Options supplémentaires

| Variable ENV                 | Description                                                                                              | Défaut                     |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------- |
| `RAILS_MAX_THREADS`          | Nombre de threads dans le pool de threads                                                               | `5`                        |
| `RAILS_HOST`                 | Hôte URL pour l'application                                                                              | `example.com`              |
| `RAILS_PORT`                 | Port sur lequel l'application s'exécute                                                                  | `3000` *lorsque `RAILS_ENV` est `development`* |
| `RAILS_PROTOCOL`             | Protocole utilisé par l'application                                                                      | `http`                     |
| `RAILS_DAILY_LOG_ROTATION`   | Faire pivoter les journaux quotidiennement. Pour l'environnement de production uniquement.              | `false`                    |
| `RAILS_LOG_TO_STDOUT`        | Activer la journalisation vers stdout                                                                    | `false`                    |
| `REDIS_URL`                  | Définir l'URL Redis                                                                                      | `redis://localhost:6379/1` |
| `DATABASE_URL`               | Définir l'URL de la base de données postgres                                                             | `nil`                      |
| `JOBS_DATABASE_URL`          | Définir l'URL de la base de données postgres jobs                                                        | `nil`                      |
| `PORT`                       | Définir le port sur lequel Puma écoute pour recevoir des requêtes                                       | `3000`                     |
| `PIDFILE`                    | Définir le fichier pid que Puma utilisera                                                                | `tmp/pids/server.pid`      |
| `RAILS_SERVE_STATIC_FILES`   | Définir pour activer le service de fichiers statiques du dossier `/public`. Par défaut, cela est géré par Apache ou NGINX. | `false`                    |
| `PUID_APP_PREFIX`            | Définir le préfixe d'identifiant unique persistant                                                       | `INXT`                     |
| `SEED_ATTACHMENT_PER_SAMPLE` | Définir le nombre de pièces jointes par échantillon lors du peuplement de la base de données avec des données de test | `2`                        |
| `ENABLE_CRON`                | Active les tâches cron de nettoyage intégrées pour les échantillons, les pièces jointes et les exportations de données. | `true`                     |
| `CRON_CLEANUP_AFTER_DAYS`    | Définir le nombre de jours qu'un échantillon/pièce jointe supprimé doit avoir avant d'être nettoyé.     | `7`                        |
| `RAILS_ENABLE_WEB_CONSOLE`    | Mode développement uniquement : Lorsque défini, une console rails sera présente sur chaque page web.    | `nil`                        |
| `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`    | Lorsque défini, la télémétrie des métriques personnalisées sera envoyée au point de terminaison de métriques spécifié. (exemple : "localhost:4318/v1/metrics").                      | `nil`                        |
| `OTEL_METRICS_SEND_INTERVAL`    | Nombre de secondes à dormir entre les appels d'envoi par lots de télémétrie.                      | `10`                        |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`    | Lorsque défini, la télémétrie de trace configurée sera envoyée au point de terminaison de traces spécifié. (exemple : "localhost:4318/v1/traces").                      | `nil`                        |
