FROM openmaptiles/openmaptiles-tools:6.1

RUN DEBIAN_FRONTEND=noninteractive apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        inotify-tools; \
    rm -rf /var/lib/apt/lists/*

ENV TILESET_FILE=openmaptiles.yaml

ARG OMT_USER=omt
ARG OMT_GROUP=omt
ARG OMT_UID=5005
ARG OMT_GID=50005

RUN groupadd -r ${OMT_GROUP} -g ${OMT_GID} && \
    useradd -m -d /home/${OMT_USER}/ -u ${OMT_UID} --gid ${OMT_GID} -s /bin/bash -G ${OMT_GROUP} ${OMT_USER}

ARG OMT_VERS=v3.13

RUN git clone https://github.com/openmaptiles/openmaptiles.git /usr/src/openmaptiles \
    && cd /usr/src/openmaptiles \
    && git checkout ${OMT_VERS} \
    && mkdir -p /sql/parallel /mapping /cache /import/borders /expired_tiles \
    && generate-imposm3 ${TILESET_FILE} > /mapping/mapping.yaml \
    && generate-sql ${TILESET_FILE} --dir /sql \
		&& generate-sqltomvt ${TILESET_FILE} \
							 --key --gzip --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> /sql/run_last.sql \
    && cp ${TILESET_FILE} /tileset \
    && cp -R layers/ /tileset \
    && chown -R "${OMT_USER}:${OMT_GROUP}" /sql /mapping /cache /import /tileset /expired_tiles \
    && cd /tileset \
    && rm -rf /usr/src/openmaptiles

RUN mkdir -p /status_osm && chown -R "${OMT_USER}:${OMT_GROUP}" /status_osm

ENV EXPIRETILES_DIR=/expired_tiles

COPY ./purge_cache/purge_cache.py ./purge_cache/purge-cache /usr/src/app/
RUN chmod +x /usr/src/app/purge_cache.py /usr/src/app/purge-cache

COPY ./envnz-dl-import-update /usr/src/app/envnz-dl-import-update
RUN chmod +x /usr/src/app/envnz-dl-import-update

USER ${OMT_USER}
