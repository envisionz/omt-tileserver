FROM varnish:7.0-alpine

RUN set -e;\
    BASE_PKGS="tar alpine-sdk automake autoconf libtool python3 py3-docutils git"; \
    apk add --virtual varnish-build-deps -q --no-progress --update $BASE_PKGS; \
    git clone https://github.com/varnish/varnish-modules.git /varnish-mods; \
    cd /varnish-mods; \
    git checkout 7.0; \
    ./bootstrap; \
    ./configure; \
    make; \
    make install-strip; \
    cd -; \
    rm -rf /varnish-mods; \
    apk del --no-network varnish-build-deps

COPY default.vcl /etc/varnish/
