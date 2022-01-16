#!/bin/sh

mbtiles=${OMT_MBTILES}

backend=${OMT_CACHE_STORAGE:-malloc}
size=${OMT_CACHE_SIZE:-1G}

postserve_host=${OMT_POSTSERVE_HOST:-postserve}
postserve_port=${OMT_POSTSERVE_PORT:-8080}

tileserver_host=${OMT_TILESERVER_HOST:-tileserver}
tileserver_port=${OMT_TILESERVER_PORT:-8080}

purge_host=${OMT_PURGE_HOST:-purge-cache}

export OMT_CACHE_ZOOM_MAX=${OMT_CACHE_ZOOM_MAX:-18}

# Cache regexes
tile_regex='/[0-9]+/[0-9]+/[0-9]+(@[0-9]x)?\.(webp|png|jpg|jpeg|pbf)'
zl_regex='^.+/([0-9]+)/[0-9]+/[0-9]+(@[0-9]x)?\.(webp|png|jpg|jpeg|pbf).*$'
xkey_regex='^.+/([0-9]+/[0-9]+/[0-9]+)(@[0-9]x)?\.(webp|png|jpg|jpeg|pbf).*$'

mvt_tile_regex='/tiles/[0-9]+/[0-9]+/[0-9]+\.pbf'
static_regex='/styles/[a-zA-Z_\-]+/static/.+\.(webp|png|jpg|jpeg)'

if [ "$backend" = "file" ]; then
    storage="file,/cache_store/store,${size}"
else
    storage="malloc,${size}"
fi

if [ -n "$mbtiles" ]; then
    cp /vcl_files/mbtiles.vcl /etc/varnish/default.vcl
else
    cp /vcl_files/postserve.vcl /etc/varnish/default.vcl
    sed -i \
        -e "s/\${postserve_host}/${postserve_host}/g" \
        -e "s/\${postserve_port}/${postserve_port}/g" \
        -e "s/\${purge_host}/${purge_host}/g" \
        -e "s/\${zl_regex}/${zl_regex}/g" \
        -e "s/\${xkey_regex}/${xkey_regex}/g" \
        -e "s/\${mvt_tile_regex}/${mvt_tile_regex}/g" \
        /etc/varnish/default.vcl || exit 1
fi
sed -i \
    -e "s/\${tileserver_host}/${tileserver_host}/g" \
    -e "s/\${tileserver_port}/${tileserver_port}/g" \
    -e "s/\${tile_regex}/${tile_regex}/g" \
    -e "s/\${static_regex}/${static_regex}/g" \
    /etc/varnish/default.vcl || exit 1

if [ -z "$mbtiles" ]; then
    # Varnish doesn't like if it can't resolve the purge host
    # on startup.
    until getent ahostsv4 "$purge_host"; do
        echo "Error resolving cache purge hostname"
        sleep 2
    done
fi

# And to be on the safe side, ensure that the tileserver
# is available
until getent ahostsv4 "$tileserver_host"; do
    echo "Error resolving cache purge hostname"
    sleep 2
done

varnishd \
    -F \
    -f /etc/varnish/default.vcl \
    -a http=:8080,HTTP \
    -a proxy=:8443,PROXY \
    -p feature=+http2 \
    -s "$storage"
