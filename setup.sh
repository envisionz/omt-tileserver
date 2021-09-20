#!/bin/sh

set -e

compose_file=docker-compose.yml
compose_file_orig="${compose_file}.orig"

printl()
{
    printf "%s\n" "$1"
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

cp "$compose_file" "$compose_file_orig"
sed -i -e 's/pgdata:/pgdata:'"\\${nl}"'    external: true/' "$compose_file"
sed -i -e 's/pgdata:/omt-tileserver-pgdata:/g' "$compose_file"

# Create 'omt-tileserver-pgdata' volume if it doesn't exist
if ! docker volume ls | grep -q omt-tileserver-pgdata; then
    docker volume create omt-tileserver-pgdata
fi

make
make start-db
make import-data
make download area="$dl_area"
make import-osm
make import-borders
make import-sql

restore_compose_file

cd -
