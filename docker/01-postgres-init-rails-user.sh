#!/bin/bash
set -e

# the script uses the DATABASE_URL env var (if set)
# to extract the username and password and set HOSTEDGPT_DB_USERNAME and HOSTEDGPT_DB_PASSWORD
# if DATABASE_URL is not set, it uses the existing HOSTEDGPT_DB_USERNAME and HOSTEDGPT_DB_PASSWORD
# to create the rails user if it doesn't already exist

if [ -n "$DATABASE_URL" ]; then
  echo "DATABASE_URL is set. Extracting username and password"
  HOSTEDGPT_DB_USERNAME="$(echo $DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')"
  HOSTEDGPT_DB_PASSWORD="$(echo $DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')"
fi

echo "creating user $HOSTEDGPT_DB_USERNAME"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOS
  DO
  \$do\$
  BEGIN
    IF EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE  rolname = '$HOSTEDGPT_DB_USERNAME') THEN

        RAISE NOTICE 'Role "$HOSTEDGPT_DB_USERNAME" already exists. Skipping.';
    ELSE
        CREATE USER $HOSTEDGPT_DB_USERNAME WITH SUPERUSER PASSWORD '$HOSTEDGPT_DB_PASSWORD';
    END IF;
  END
  \$do\$;
EOS
