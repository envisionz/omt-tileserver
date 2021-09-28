#!/bin/bash

set -e

printl()
{
    printf "%s\n" "$1"
}

default_postserve_host="http://postserve:8080"

postsrv_host="${TILE_POSTSERVE_HOST:-$default_postserve_host}"

domains=${TILE_DOMAINS:-'localhost:8181,127.0.0.1:8181'}

# min_zoom=${TILE_MIN_ZOOM:-0}
# max_zoom=${TILE_MAX_ZOOM:-20}

bounds=${TILE_BOUNDS:-'-180,-85.0511,180,85.0511'}

center=${TILE_CENTER:-'0,0,2'}

attribution=${TILE_ATTR:-'<a href="https://openmaptiles.org/">© OpenMapTiles</a> <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'}

format=${TILE_FORMAT:-png}

cd /data/styles

declare -A styles

styles[bright]=osm-bright-gl-style/style-local.json
styles[basic]=maptiler-basic-gl-style/style-local.json
styles[darkmatter]=dark-matter-gl-style/style-local.json
styles[positron]=positron-gl-style/style-local.json
styles[liberty]=osm-liberty/style.json

tmp_style=".style.json.tmp"
tmp_config=".config.json.tmp"

for style in ${!styles[@]}; do
    cp "${styles[$style]}" "$tmp_style"
    jq --arg p "$postsrv_host" \
        '.sources.openmaptiles.url = $p | .glyphs = "{fontstack}/{range}.pbf"' \
        "$tmp_style" > "${styles[$style]}"
    rm "$tmp_style"
    
    cp /data/config.json "$tmp_config"
    jq --arg sk "$style" --arg sf "${styles[$style]}" --arg b "$bounds" --arg c "$center" --arg f "$format" --arg a "$attribution" \
        '.styles += {($sk): {"style": $sf, "tilejson":{"format": $f, "attribution": $a, "bounds": [], "center": []}}} |
         .styles[$sk].tilejson.bounds = ($b | split(",")) |
         .styles[$sk].tilejson.bounds[] |= tonumber |
         .styles[$sk].tilejson.center = ($c | split(",")) |
         .styles[$sk].tilejson.center[] |= tonumber' \
         "$tmp_config" > /data/config.json
    rm "$tmp_config"
done

# Global config options
cp /data/config.json "$tmp_config"
jq --arg d "$domains" \
    '.options.domains = ($d | split(","))' \
    "$tmp_config" > /data/config.json
rm "$tmp_config"

# If a status directory is mounted, delay start
if [ -d /status ]; then
    printl "Waiting for OSM import to complete"
    until [ -f /status/osm-import ]; do
        sleep 2
    done
    # Give Postserve a bit of grace
    sleep 1
fi

/app/docker-entrypoint.sh "$@"
