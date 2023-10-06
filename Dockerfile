# hivemind
FROM alpine as hivemind

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_HIVEMIND_OWNER=DarthSim
ARG GITHUB_HIVEMIND_REPOSITORY=hivemind
ARG GITHUB_HIVEMIND_REVISION=580abe5b3faf585c450604227e40e960cdbb21bd

RUN apk add --update --no-cache --virtual hivemind-build git go \
  \
  && mkdir -p /src && cd /src \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_HIVEMIND_OWNER}/${GITHUB_HIVEMIND_REPOSITORY}.git \
  && git fetch --depth 1 origin ${GITHUB_HIVEMIND_REVISION} \
  && git reset --hard ${GITHUB_HIVEMIND_REVISION} \
  \
  && env CGO_ENABLED=0 go build -v -o /app/bin/hivemind . \
  \
  && apk del --purge hivemind-build \
  && cd / && rm -rf /src \
  && rm -rf /root/.cache /root/go

# litestream
FROM alpine as litestream

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=e0493f979a8269a53b83b35939d0820f0a3a4fc1
ARG GITHUB_LITESTREAM_VERSION=v0.3.11

RUN apk add --update --no-cache --virtual litestream-build \
      build-base \
      git \
      go \
    \
    && mkdir -p /src && cd /src \
    \
    && git init \
    && git remote add origin https://github.com/${GITHUB_LITESTREAM_OWNER}/${GITHUB_LITESTREAM_REPOSITORY}.git \
    && git fetch --depth 1 origin ${GITHUB_LITESTREAM_REVISION} \
    && git reset --hard ${GITHUB_LITESTREAM_REVISION} \
    \
    && go build \
      -v \
      -ldflags "main.Version=${GITHUB_LITESTREAM_VERSION}' -extldflags '-static'" \
      -tags osusergo,netgo,sqlite_omit_load_extension \
      -o /app/bin/litestream ./cmd/litestream \
    \
    && apk del --purge litestream-build \
    && cd / && rm -rf /src \
    && rm -rf /root/.cache /root/go

# h2o
FROM alpine as h2o

RUN mkdir -p /app
WORKDIR /

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=cb9f500d0854b167862b3c599e4b89212d66c5c6

RUN apk add --update --no-cache --virtual h2o-build \
      bison \
      build-base \
      ca-certificates \
      cmake \
      git \
      linux-headers \
      openssl-dev \
      perl \
      ruby \
      ruby-dev \
      ruby-rake \
      zlib-dev \
  \
  && mkdir -p src && cd src \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_H2O_OWNER}/${GITHUB_H2O_REPOSITORY}.git \
  && git fetch --depth 1 origin ${GITHUB_H2O_REVISION} \
  && git reset --hard ${GITHUB_H2O_REVISION} \
  && git submodule update --init --recursive \
  \
  && mkdir -p build && cd build \
  && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/app \
    -DWITH_MRUBY=ON \
  && make && make install \
  \
  && apk del --purge h2o-build \
  && cd / && rm -rf /src

# gotosocial
FROM alpine as gotosocial

RUN mkdir -p /app/bin /web/www
WORKDIR /

ARG GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
ARG GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
ARG GITHUB_GOTOSOCIAL_REVISION=c7a46e05dbca86b30123cb1c45c1457bbc7a9c4b
ARG GITHUB_GOTOSOCIAL_VERSION=v0.11.1

RUN apk add --update --no-cache --virtual gotosocial-build \
  \
  build-base \
  git \
  go \
  nodejs \
  yarn \
  && mkdir -p /src && cd /src \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_GOTOSOCIAL_OWNER}/${GITHUB_GOTOSOCIAL_REPOSITORY}.git \
  && git fetch --depth 1 origin ${GITHUB_GOTOSOCIAL_REVISION} \
  && git reset --hard ${GITHUB_GOTOSOCIAL_REVISION} \
  \
  && cd ./web/source \
  && yarn install \
  && BUDO_BUILD=1 node index.js \
  && cd .. \
  && rm -rf source \
  && cp -R assets /web/www/assets \
  && cp -R template /web/templates \
  && cd .. \
  \
  && VERSION=${GITHUB_GOTOSOCIAL_VERSION} ./scripts/build.sh \
  && cp gotosocial /app/bin/gotosocial \
  \
  && apk del --purge gotosocial-build \
  && cd / && rm -rf /src \
  && rm -rf /root/.cache /root/go

# runtime
FROM alpine as runtime

RUN apk add --update --no-cache ca-certificates openssl
WORKDIR /

COPY --from=h2o /app /app
COPY --from=hivemind /app/bin/hivemind /app/bin/
COPY --from=litestream /app/bin/litestream /app/bin/
COPY --from=gotosocial /app/bin/gotosocial /app/bin/
RUN chmod +x /app/bin/*

COPY --from=gotosocial /web /web
COPY --from=gotosocial /web/www/assets/default_avatars /web/www/default_avatars
COPY web/www/logo.png /web/www/assets/logo.png
COPY web/www/ads.txt /web/www/ads.txt

RUN find /web -type d -exec chmod 0500 {} \; \
  && find /web -type f -exec chmod 0400 {} \; \
  && chown -R nobody:nobody -R /web

RUN mkdir -p /var/run/kalaclista
COPY runtime/Procfile /var/run/kalaclista/Procfile
COPY runtime/h2o.json /var/run/kalaclista/h2o.conf
COPY runtime/litestream.json /var/run/kalaclista/litestream.yml
COPY runtime/gotosocial.json /var/run/kalaclista/gotosocial.yml

RUN mkdir -p /data

ENV PATH /app/bin:$PATH
WORKDIR /var/run/kalaclista

ENTRYPOINT ["/app/bin/hivemind"]
