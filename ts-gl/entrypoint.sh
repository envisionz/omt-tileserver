#!/bin/bash

set -e

printl()
{
    printf "%s\n" "$1"
}

postsrv_host="http://${OMT_POSTSERVE_HOST:-postserve}:${OMT_POSTSERVE_PORT:-8080}/"

domains=${OMT_TILESERVER_DOMAINS:-'localhost:8181,127.0.0.1:8181'}

bounds=${OMT_TILESERVER_BOUNDS:-'-180,-85.0511,180,85.0511'}

center=${OMT_TILESERVER_CENTER:-'0,0,2'}

attribution=${OMT_TILESERVER_ATTR:-'<a href="https://openmaptiles.org/">© OpenMapTiles</a> <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'}

format=${OMT_TILESERVER_FMT:-png}

min_rend=${OMT_TILESERVER_MIN_REND_POOL_SZ:-8,4,2}
max_rend=${OMT_TILESERVER_MAX_REND_POOL_SZ:-16,8,4}

tile_margin=${OMT_TILESERVER_MARGIN:-0}

front_page=${OMT_TILESERVER_FRONT_PAGE:-true}

mb_tiles_file=/data/mbtiles/tiles.mbtiles

src_omt_url="$postsrv_host"

if [ -f "$mb_tiles_file" ]; then
    src_omt_url="mbtiles://tiles.mbtiles"
fi

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
    jq --arg u "$src_omt_url" \
        '.sources.openmaptiles.url = $u | .glyphs = "{fontstack}/{range}.pbf"' \
        "$tmp_style" > "${styles[$style]}"
    rm "$tmp_style"
    
    cp /data/config.json "$tmp_config"
    jq --arg sk "$style" --arg sf "${styles[$style]}" --arg b "$bounds" \
        --arg c "$center" --arg f "$format" --arg a "$attribution" \
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
jq --arg d "$domains" --arg min "$min_rend" --arg max "$max_rend" --arg tm "$tile_margin" \
    --arg p "$tileserver_path" --arg f "$front_page" --arg u "$src_omt_url" --arg mb "$(basename "$mb_tiles_file")" \
    '.options.domains = ($d | split(",")) | 
     .options.minRendererPoolSizes = ($min | split(",")) |
     .options.minRendererPoolSizes[] |= tonumber |
     .options.maxRendererPoolSizes = ($max | split(",")) |
     .options.maxRendererPoolSizes[] |= tonumber | 
     .options.tileMargin = ($tm | tonumber) | 
     .options.paths.root = $p | 
     .options.frontPage = ($f | test("^(true|t|1)$"; "i")) |
     if $u == "mbtiles://tiles.mbtiles" then .data += {"omt": {"mbtiles": $mb }} else del(.data) end' \
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
