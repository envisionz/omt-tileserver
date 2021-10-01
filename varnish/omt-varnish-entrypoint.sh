#!/bin/sh

backend=${OMT_CACHE_STORAGE:-malloc}
size=${OMT_CACHE_SIZE:-1G}

postserve_host=${OMT_POSTSERVE_HOST:-postserve}
tileserver_host=${OMT_TILESERVER_HOST:-tileserver}
purge_host=${OMT_PURGE_HOST}

export OMT_CACHE_ZOOM_MAX=${OMT_CACHE_ZOOM_MAX:-18}

if [ "$backend" = "file" ]; then
    storage="file,/cache_store/store,${size}"
else
    storage="malloc,${size}"
fi

if [ ! -z "${purge_host// }" ]; then
    purge_host="\"${purge_host}\";"
fi

sed -i \
    -e "s/\${postserve_host}/${postserve_host}/g" \
    -e "s/\${tileserver_host}/${tileserver_host}/g" \
    -e "s/\"\${purge_host}\";/${purge_host}/g" \
    /etc/varnish/default.vcl || exit 1

varnishd \
    -F \
    -f /etc/varnish/default.vcl \
    -a http=:80,HTTP \
    -a proxy=:8443,PROXY \
    -p feature=+http2 \
    -s "$storage"
