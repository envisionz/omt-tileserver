#!/bin/sh

set -e

compose_file=docker-compose.yml
compose_file_orig="${compose_file}.orig"

printl()
{
    printf "[OMT-Tileserver] %s\n" "$1"
}

restore_compose_file()
{
    if [ -f "$compose_file_orig" ]; then
        rm -f "$compose_file"
        cp "$compose_file_orig" "$compose_file"
        rm -f "$compose_file_orig"
    fi
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

nl='
'

# Modify the OpenMapTile docker-compose file to make the postgres data volume external
cd openmaptiles

restore_compose_file

cp "$compose_file" "$compose_file_orig" && rm "$compose_file" && cp ../omt-dc.yml "$compose_file"

# Start with a clean slate
printl "Running 'make clean'..."
make clean
printl "Destroying existing DB..."
make destroy-db

# Recreate 'omt-tileserver-pgdata' volume
if docker volume ls | grep -q omt-tileserver-pgdata; then
    docker volume rm omt-tileserver-pgdata
fi
docker volume create omt-tileserver-pgdata

printl "Initialising..."
make
printl "Starting DB..."
make start-db
printl "Importing common data..."
make import-data
printl "Downloading area: ${dl_area}..."
make download area="$dl_area"
printl "Importing area: ${dl_area}..."
make import-osm
printl "Importing borders..."
make import-borders
printl "Importing SQL..."
make import-sql

make stop-db
docker-compose down postgres

restore_compose_file

cd -
