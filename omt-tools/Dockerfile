FROM openmaptiles/openmaptiles-tools:5.3-imposm10

ENV TILESET_FILE=openmaptiles.yaml

RUN git clone https://github.com/openmaptiles/openmaptiles.git /usr/src/openmaptiles \
    && cd /usr/src/openmaptiles \
    && git checkout v3.12.2 \
    && mkdir -p /sql/parallel /mapping /cache /import/borders \
    && generate-imposm3 ${TILESET_FILE} > /mapping/mapping.yaml \
    && generate-sql ${TILESET_FILE} --dir /sql \
		&& generate-sqltomvt ${TILESET_FILE} \
							 --key --gzip --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> /sql/run_last.sql \
    && cp ${TILESET_FILE} /tileset \
    && cp -R layers/ /tileset \
    && cd /tileset \
    && rm -rf /usr/src/openmaptiles

COPY ./envnz-dl-import-update /usr/src/app/envnz-dl-import-update
RUN chmod +x /usr/src/app/envnz-dl-import-update
