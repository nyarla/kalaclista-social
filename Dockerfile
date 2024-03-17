# shoreman
FROM alpine:3.19 as shoreman

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
FROM golang:1.21.8-alpine as litestream

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
      -trimpath -v \
      -ldflags "-X 'main.Version=${GITHUB_LITESTREAM_VERSION}' -s -w -extldflags '-static' -buildid=" \
      -tags osusergo,netgo,sqlite_omit_load_extension \
      -o /app/bin/litestream ./cmd/litestream \
    \
    && apk del --purge litestream-build \
    && cd / && rm -rf /src /root

# h2o
FROM alpine:3.19 as h2o

RUN mkdir -p /app
WORKDIR /

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=653fccf538aa2f2424946f56d39e5de96921c4bb

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
FROM golang:1.21.8-alpine as gotosocial

RUN mkdir -p /app/bin /web/www
WORKDIR /

ARG GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
ARG GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
ARG GITHUB_GOTOSOCIAL_REVISION=fb3e3ca10dc44cba841019bee1a8812e746133e9
ARG GITHUB_GOTOSOCIAL_VERSION=v0.13.3

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
  && cp -R assets /web/www/assets \
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
FROM alpine:3.19 as runtime

RUN apk add --update --no-cache ca-certificates openssl bash
WORKDIR /

COPY --from=h2o /app /app
COPY --from=shoreman --chmod=0500 /app/bin/shoreman /app/bin/
COPY --from=litestream --chmod=0500 /app/bin/litestream /app/bin/
COPY --from=gotosocial --chmod=0500 /app/bin/gotosocial /app/bin/

COPY --from=gotosocial /web /web
COPY web/ /web/
RUN chown -R nobody:nobody /web && chmod -R -w /web

WORKDIR /var/run/kalaclista
COPY --chmod=0400 runtime/Procfile /var/run/kalaclista/Procfile
COPY --chmod=0400 runtime/h2o.json /var/run/kalaclista/h2o.conf
COPY --chmod=0400 runtime/litestream.json /var/run/kalaclista/litestream.yml
COPY --chmod=0400 runtime/gotosocial.json /var/run/kalaclista/gotosocial.yml

RUN mkdir -p /data
ENV PATH /app/bin:$PATH
ENV GODEBUG=madvdontneed=1

ENTRYPOINT ["/app/bin/shoreman", "Procfile"]
