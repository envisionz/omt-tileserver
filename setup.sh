#!/bin/sh

set -e

printl()
{
    printf "%s\n" "$1"
}

restore_compose_file()
{
    if [ -f docker-compose.yml.orig ]; then
        rm -f docker-compose.yml
        cp docker-compose.yml.orig docker-compose.yml
        rm -f docker-compose.yml.orig
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

cp docker-compose.yml docker-compose.yml.orig
sed -i -e 's/pgdata:/pgdata:'"\\${nl}"'    external: true/' docker-compose.yml
sed -i -e 's/pgdata:/omt-tileserver-pgdata:/g' docker-compose.yml

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
