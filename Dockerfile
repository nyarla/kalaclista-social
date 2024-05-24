# litestream
FROM golang:1.21.8-alpine as goreman

RUN mkdir -p /opt/bin
WORKDIR /

ARG GITHUB_GOREMAN_OWNER=mattn
ARG GITHUB_GOREMAN_REPOSITORY=goreman
ARG GITHUB_GOREMAN_REVISION=ebb9736b7c7f7f3425280ab69e1f7989fb34eadc
ARG GITHUB_GOREMAN_VERSION=0.3.15

RUN apk add --update --no-cache --virtual goreman-build \
      build-base \
      git \
    \
    && mkdir -p /src && cd /src \
    \
    && git init \
    && git remote add origin https://github.com/${GITHUB_GOREMAN_OWNER}/${GITHUB_GOREMAN_REPOSITORY}.git \
    && git fetch --depth 1 origin ${GITHUB_GOREMAN_REVISION} \
    && git reset --hard ${GITHUB_GOREMAN_REVISION} \
    \
    && go build \
      -trimpath -v \
      -ldflags "-X 'main.Version=${GITHUB_GOREMAN_VERSION}' -s -w -extldflags '-static' -buildid=" \
      -o /opt/bin/goreman . \
    \
    && apk del --purge goreman-build \
    && cd / && rm -rf /src /root



# litestream
FROM golang:1.21.8-alpine as litestream

RUN mkdir -p /opt/bin
WORKDIR /

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=5be467a478adcffc5b3999b9503cc676c2bf09f1
ARG GITHUB_LITESTREAM_VERSION=git

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
      -o /opt/bin/litestream ./cmd/litestream \
    \
    && apk del --purge litestream-build \
    && cd / && rm -rf /src /root

# h2o
FROM alpine:3.19 as h2o

RUN mkdir -p /opt
WORKDIR /

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=40422536fbf7f834da1e312058aa51db3a191c29

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
    -DCMAKE_INSTALL_PREFIX=/opt \
    -DWITH_MRUBY=ON \
  && make && make install && chmod -R -w /opt \
  \
  && apk del --purge h2o-build \
  && cd / && rm -rf /src /root

# gotosocial
FROM golang:1.21.8-alpine as gotosocial

RUN mkdir -p /opt/bin /web/www
WORKDIR /

ARG GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
ARG GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
ARG GITHUB_GOTOSOCIAL_REVISION=15733cddb22de81475d1934be100cd3960668c43
ARG GITHUB_GOTOSOCIAL_VERSION=v0.15.0

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
  && cp gotosocial /opt/bin/gotosocial \
  \
  && apk del --purge gotosocial-build \
  && cd / && rm -rf /src /root

# runtime
FROM alpine:3.19 as runtime

RUN apk add --update --no-cache ca-certificates openssl bash
WORKDIR /

COPY --from=h2o /opt /opt
COPY --from=goreman --chmod=0500 /opt/bin/goreman /opt/bin/
COPY --from=litestream --chmod=0500 /opt/bin/litestream /opt/bin/
COPY --from=gotosocial --chmod=0500 /opt/bin/gotosocial /opt/bin/

COPY --from=gotosocial /web /web
COPY web/ /web/
RUN chown -R nobody:nobody /web && chmod -R -w /web

WORKDIR /var/lib/kalaclista
COPY --chmod=0400 runtime/Procfile /var/lib/kalaclista/Procfile
COPY --chmod=0400 runtime/h2o.json /var/lib/kalaclista/h2o.conf
COPY --chmod=0400 runtime/litestream.json /var/lib/kalaclista/litestream.yml
COPY --chmod=0400 runtime/gotosocial.json /var/lib/kalaclista/gotosocial.yml

RUN mkdir -p /data
ENV PATH /opt/bin:$PATH
ENV GODEBUG=madvdontneed=1

ENTRYPOINT ["/opt/bin/goreman", "start"]
