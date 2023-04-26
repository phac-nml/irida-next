#!/bin/sh
set -e

run_pending_migrations=${RUN_PENDING_MIGRATIONS:-false}
# run any pending migrations if RUN_PENDING_MIGRATIONS=true
if ( $run_pending_migrations = "true" ); then
    echo "Running pending migrations"
    bin/rails db:migrate
fi

# Exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@"
