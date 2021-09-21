#!/bin/bash

set -e

printl()
{
    printf "%s\n" "$1"
}

default_postserve_host="http://postserve:8080"

postsrv_host="${TILE_POSTSERVE_HOST:-$default_postserve_host}"

domains=${TILE_DOMAINS:-'localhost:8181,127.0.0.1:8181'}

min_zoom=${TILE_MIN_ZOOM:-0}
max_zoom=${TILE_MAX_ZOOM:-20}
bounds=${TILE_BOUNDS:-'-180,-85.0511,180,85.0511'}
center=${TILE_CENTER:-'0,0,2'}
attribution=${TILE_ATTR:-'<a href="https://openmaptiles.org/">© OpenMapTiles</a> <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'}
formats=${TILE_FORMAT:-'png'}

cd /data/styles

declare -A styles

styles[bright]=osm-bright-gl-style/style-local.json
styles[basic]=maptiler-basic-gl-style/style-local.json
styles[darkmatter]=dark-matter-gl-style/style-local.json
styles[positron]=positron-gl-style/style-local.json
styles[liberty]=osm-liberty/style.json

tmp_config=/tmp/config.json

for style in ${!styles[@]}; do
    cp "${styles[$style]}" /tmp/style.json
    jq --arg p "$postsrv_host" \
        '.sources.openmaptiles.url = $p | .glyphs = "{fontstack}/{range}.pbf"' \
        /tmp/style.json > "${styles[$style]}"
    rm /tmp/style.json
    
    cp /data/config.json "$tmp_config"
    jq --arg sk "$style" --arg sf "${styles[$style]}" 
done

/app/docker-entrypoint.sh "$@"
