FROM node:10-buster AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get -y upgrade \
  && apt-get -y --no-install-recommends install \
      apt-transport-https \
      curl \
      unzip \
      build-essential \
      python \
      libcairo2-dev \
      libgles2-mesa-dev \
      libgbm-dev \
      libllvm7 \
      libprotobuf-dev \
      git \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/maptiler/tileserver-gl.git /usr/src/app \
    && cd /usr/src/app \
    && git checkout 8680a8006a13a46e5c4816a3085816c2d7cac174

ENV NODE_ENV="production"

RUN cd /usr/src/app && npm install --production

COPY fonts /usr/src/fonts

RUN cd /usr/src/fonts && npm install && node ./generate.js && ls -l ./_output

FROM node:10-buster-slim AS final

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get upgrade \
  && apt-get -y --no-install-recommends install \
      libgles2-mesa \
      libegl1 \
      xvfb \
      xauth \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app /app

ENV NODE_ENV="production"
ENV CHOKIDAR_USEPOLLING=1
ENV CHOKIDAR_INTERVAL=500

VOLUME /data
WORKDIR /data

EXPOSE 8080

USER node:node

ENTRYPOINT ["/app/docker-entrypoint.sh"]

CMD ["-p", "8080"]