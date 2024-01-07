# shoreman
FROM alpine as shoreman

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_SHOREMAN_URL="https://raw.githubusercontent.com/chrismytton/shoreman/master/shoreman.sh"
ARG GITHUB_SHOREMAN_SHA256="a21acce3072bb8594565094e4a9bbafd3b9d7fa04abd7e0c74c19fd479adb817"

RUN apk add --update --no-cache --virtual shoreman curl coreutils \
  \
  && curl -o /app/bin/shoreman "${GITHUB_SHOREMAN_URL}" \
  && test "$(sha256sum /app/bin/shoreman | cut -d ' ' -f 1)" = "${GITHUB_SHOREMAN_SHA256}" \
  && chmod -R +x /app/bin \
  && apk del --purge shoreman

# litestream
FROM golang:1.21.3-alpine as litestream

RUN mkdir -p /app/bin
WORKDIR /

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=977d4a5ee45ae546537324a3cfbf926de3bebc97
ARG GITHUB_LITESTREAM_VERSION=v0.3.13

RUN apk add --update --no-cache --virtual litestream-build \
      build-base \
      git \
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
    && cd / && rm -rf /src /root

# h2o
FROM alpine:edge as h2o

RUN mkdir -p /app
WORKDIR /

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=5c78fc1e3e7fd987cf699c9684e5b8483608e492

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
  && make && make install && chmod -R -w /app \
  \
  && apk del --purge h2o-build \
  && cd / && rm -rf /src /root

# gotosocial
FROM golang:1.21.3-alpine as gotosocial

RUN mkdir -p /app/bin /web/www
WORKDIR /

ARG GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
ARG GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
ARG GITHUB_GOTOSOCIAL_REVISION=f4fcffc8b56ef73c184ae17892b69181961c15c7
ARG GITHUB_GOTOSOCIAL_VERSION=v0.13.0

RUN apk add --update --no-cache --virtual gotosocial-build \
  \
  build-base \
  git \
  nodejs \
  yarn  \
  && mkdir -p /src && cd /src \
  \
  && git init \
  && git remote add origin https://github.com/${GITHUB_GOTOSOCIAL_OWNER}/${GITHUB_GOTOSOCIAL_REPOSITORY}.git \
  && git fetch --depth 1 origin ${GITHUB_GOTOSOCIAL_REVISION} \
  && git reset --hard ${GITHUB_GOTOSOCIAL_REVISION} \
  \
  && yarn --cwd ./web/source install && yarn --cwd ./web/source ts-patch install \
  && yarn --cwd ./web/source build && cd web \
  && cp -R assets /web/www/assets && cp -R assets/default_avatars /web/www/ \
  && cp -R template /web/templates \
  && chmod -R -w /web && chown -R nobody:nobody /web \
  && cd .. \
  \
  && VERSION=${GITHUB_GOTOSOCIAL_VERSION} ./scripts/build.sh \
  && cp gotosocial /app/bin/gotosocial \
  \
  && apk del --purge gotosocial-build \
  && cd / && rm -rf /src /root

# runtime
FROM alpine as runtime

RUN apk add --update --no-cache ca-certificates openssl bash
WORKDIR /

COPY --from=h2o /app /app
COPY --from=shoreman --chmod=0500 /app/bin/shoreman /app/bin/
COPY --from=litestream --chmod=0500 /app/bin/litestream /app/bin/
COPY --from=gotosocial --chmod=0500 /app/bin/gotosocial /app/bin/

COPY --from=gotosocial /web /web
COPY --chmod=0400 --chown=nobody:nobody web/www/logo.png /web/www/assets/logo.png
COPY --chmod=0400 --chown=nobody:nobody web/www/ads.txt /web/www/ads.txt

WORKDIR /var/run/kalaclista
COPY --chmod=0400 runtime/Procfile /var/run/kalaclista/Procfile
COPY --chmod=0400 runtime/h2o.json /var/run/kalaclista/h2o.conf
COPY --chmod=0400 runtime/litestream.json /var/run/kalaclista/litestream.yml
COPY --chmod=0400 runtime/gotosocial.json /var/run/kalaclista/gotosocial.yml

RUN mkdir -p /data
ENV PATH /app/bin:$PATH

ENTRYPOINT ["/app/bin/shoreman", "Procfile"]
