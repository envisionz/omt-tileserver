#!/bin/bash

set -e

printl()
{
    printf "%s\n" "$1"
}

default_postserve_host="http://postserve:8080"

postsrv_host="${POSTSERVE_HOST:-$default_postserve_host}"

cd /data/styles

styles=(osm-bright-gl-style/style-local.json \
    maptiler-basic-gl-style/style-local.json \
    maptiler-terrain-gl-style/style-local.json \
    dark-matter-gl-style/style-local.json \
    positron-gl-style/style-local.json \
    osm-liberty/style.json)

for style in ${styles[@]}; do
    cp "$style" /tmp/style.json
    jq --arg p "$postsrv_host" \
        '.sources.openmaptiles.url = $p | .glyphs = "{fontstack}/{range}.pbf"' \
        /tmp/style.json > "$style"
    rm /tmp/style.json
done

/app/docker-entrypoint.sh "$@"
