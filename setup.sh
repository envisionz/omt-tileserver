#!/bin/sh

set -e

new_compose_file="../omt-dc.yml"
compose_file=docker-compose.yml
compose_file_orig="${compose_file}.orig"

new_env_file="../omt.env"
env_file=".env"
env_file_orig="${env_file}.orig"

pg_env_file=".env-postgres"
pg_env_file_orig="${pg_env_file}.orig"

printl()
{
    printf "[OMT-Tileserver] %s\n" "$1"
}

clean_omt_submodule()
{
    # Test that we're actually in the 'openmaptiles' submodule before performing git reset/clean
    if [ -f ./openmaptiles.yaml ] && [ -d ./layers ] && [ ! -d ./openmaptiles ]; then
        printl "Cleaning 'openmaptiles' submodule"
        git reset --hard HEAD
        git clean -fd
    fi
}

copy_omt_files()
{
    ([ -f "$compose_file" ] && [ -f "$new_compose_file" ]) || return 1
    ([ -f "$env_file" ] && [ -f "$new_env_file" ]) || return 1
    (cp "$compose_file" "$compose_file_orig" && rm "$compose_file" && cp "$new_compose_file" "$compose_file") || return 1
    (cp "$env_file" "$env_file_orig" && rm "$env_file" && cp "$new_env_file" "$env_file") || return 1

    cp "$pg_env_file" "$pg_env_file_orig" && rm "$pg_env_file"
    for pgvar in "PGDATABASE=" "PGUSER=" "PGPASSWORD="; do
        grep "$pgvar" "$env_file" >> "$pg_env_file"
    done
    sed -i \
        -e 's/PGDATABASE/POSTGRES_DB/g' -e 's/PGUSER/POSTGRES_USER/g' -e 's/PGPASSWORD/POSTGRES_PASSWORD/g' \
        "$pg_env_file" || return 1
    return 0
}

reset_db()
{
    make destroy-db || return 1
}

cleanup()
{
    clean_omt_submodule
    exit 1
}

if [ "$1" = "list-area" ]; then
    cd openmaptiles
    make list-geofabrik
    cd -
    exit 0
elif [ -z "$1" ]; then
    printl "Specify area to download, or 'list-area' to get list of available areas to download."
    exit 1
fi

dl_area="$1"

cd openmaptiles

printl "Restoring original files if required..."
clean_omt_submodule

printl "Copying customized OMY files..."
copy_omt_files || (printl "Cannot copy Customized OMT file" && cleanup)

# Start with a clean slate
printl "Running 'make clean'..."
make clean || cleanup
printl "Cleaning data and cahce directories..."
rm -rf ./data/* ./cache/* || cleanup
printl "Destroying existing DB..."
reset_db || cleanup

# Recreate 'omt-tileserver-pgdata' volume
if docker volume ls | grep -q omt-tileserver-pgdata; then
    docker volume rm omt-tileserver-pgdata || cleanup
fi
docker volume create omt-tileserver-pgdata || cleanup

printl "Initialising..."
make || cleanup
printl "Starting DB..."
make start-db || cleanup
printl "Downloading area: ${dl_area}..."
make download area="$dl_area" || cleanup
printl "Importing common data..."
make import-data || cleanup
printl "Importing area: ${dl_area}..."
make import-osm || cleanup
printl "Importing borders..."
make import-borders || cleanup
printl "Importing SQL..."
make import-sql || cleanup

reset_db || cleanup

clean_omt_submodule

cd -
