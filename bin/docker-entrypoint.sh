#!/bin/bash
set -e

run_pending_migrations="${RUN_PENDING_MIGRATIONS:-false}"
# run any pending migrations if RUN_PENDING_MIGRATIONS=true
if [[ $run_pending_migrations = "true" || $run_pending_migrations = "True" || $run_pending_migrations = "1" ]]; then
    echo "Running pending migrations"
    #bin/rails db:migrate
fi

# Exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@"
