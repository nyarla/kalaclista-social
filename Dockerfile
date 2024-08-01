# The build environment for compile applications
FROM debian:bookworm-slim as buildenv-gcc
RUN   apt-get update \
  &&  apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    cmake=3.25.1-1 \
    git=1:2.39.2-1.1 \
    libssl-dev=3.0.13-1~deb12u1 \
    openssl=3.0.13-1~deb12u1 \
    perl=5.36.0-7+deb12u1 \
    rake=13.0.6-3 \
    ruby-dev=1:3.1 \
    ruby=1:3.1 \
    zlib1g-dev=1:1.2.13.dfsg-1 \
  && rm /var/lib/apt/lists/* -rf

# The build environment for go applications
FROM golang:1.22.5-bookworm as buildenv-go

# Install build dependences for middlewares
RUN   apt-get update \
  &&  apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    git=1:2.39.2-1.1 \
    yarnpkg=1.22.19+~cs24.27.18-2+deb12u1 \
  && rm /var/lib/apt/lists/* -rf

# Build goremon from source code
FROM buildenv-go as goreman

ARG GITHUB_GOREMAN_OWNER=mattn
ARG GITHUB_GOREMAN_REPOSITORY=goreman
ARG GITHUB_GOREMAN_REVISION=ebb9736b7c7f7f3425280ab69e1f7989fb34eadc
ARG GITHUB_GOREMAN_VERSION=0.3.15

# Clone source code from GitHub, and build it
WORKDIR /src
RUN   git init \
  &&  git remote add origin https://github.com/${GITHUB_GOREMAN_OWNER}/${GITHUB_GOREMAN_REPOSITORY}.git \
  &&  git fetch --depth 1 origin ${GITHUB_GOREMAN_REVISION} \
  &&  git reset --hard ${GITHUB_GOREMAN_REVISION} \
  \
  && go build \
    -trimpath -v \
    -ldflags "-X 'main.Version=${GITHUB_GOREMAN_VERSION}' -s -w -extldflags '-static' -buildid=" \
    -o /goreman .

# Build litestream from source code
FROM buildenv-go as litestream

ARG GITHUB_LITESTREAM_OWNER=benbjohnson
ARG GITHUB_LITESTREAM_REPOSITORY=litestream
ARG GITHUB_LITESTREAM_REVISION=5be467a478adcffc5b3999b9503cc676c2bf09f1
ARG GITHUB_LITESTREAM_VERSION=git

# Clone source code from GitHub, and build it
WORKDIR /src
RUN   git init \
  &&  git remote add origin https://github.com/${GITHUB_LITESTREAM_OWNER}/${GITHUB_LITESTREAM_REPOSITORY}.git \
  &&  git fetch --depth 1 origin ${GITHUB_LITESTREAM_REVISION} \
  &&  git reset --hard ${GITHUB_LITESTREAM_REVISION} \
  \
  && go build \
    -trimpath -v \
    -ldflags "-X 'main.Version=${GITHUB_LITESTREAM_VERSION}' -s -w -extldflags '-static' -buildid=" \
    -tags osusergo,netgo,sqlite_omit_load_extension \
    -o /litestream ./cmd/litestream

# Build h2o from source code
FROM buildenv-gcc as h2o

ARG GITHUB_H2O_OWNER=h2o
ARG GITHUB_H2O_REPOSITORY=h2o
ARG GITHUB_H2O_REVISION=16b13eee8ad7895b4fe3fcbcabee53bd52782562

WORKDIR /src
RUN   git init \
  &&  git remote add origin https://github.com/${GITHUB_H2O_OWNER}/${GITHUB_H2O_REPOSITORY}.git \
  &&  git fetch --depth 1 origin ${GITHUB_H2O_REVISION} \
  &&  git reset --hard ${GITHUB_H2O_REVISION} \
  &&  git submodule update --init --recursive \
  \
  &&  mkdir -p build && cd build \
  &&  cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt \
        -DWITH_MRUBY=ON \
  && make && make install

# Build GoToSocial from source code
FROM buildenv-go as gotosocial

RUN mkdir -p /opt/bin /web/www
WORKDIR /

ARG GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
ARG GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
ARG GITHUB_GOTOSOCIAL_REVISION=f1cbf6fb761670e10eb8e3fecdc57578733186a1
ARG GITHUB_GOTOSOCIAL_VERSION=v0.16.0

WORKDIR /web/www
WORKDIR /src
RUN   git init \
  &&  git remote add origin https://github.com/${GITHUB_GOTOSOCIAL_OWNER}/${GITHUB_GOTOSOCIAL_REPOSITORY}.git \
  &&  git fetch --depth 1 origin ${GITHUB_GOTOSOCIAL_REVISION} \
  &&  git reset --hard ${GITHUB_GOTOSOCIAL_REVISION} \
  \
  &&  yarnpkg --cwd ./web/source install --frozen-lockfile && yarnpkg --cwd ./web/source ts-patch install \
  &&  yarnpkg --cwd ./web/source build && cd web \
  &&  cp -R assets /web/www/assets \
  &&  cp -R template /web/templates \
  &&  chmod -R -w /web && chown -R nobody /web \
  &&  cd .. \
  \
  &&  VERSION=${GITHUB_GOTOSOCIAL_VERSION} ./scripts/build.sh \
  &&  cp gotosocial /gotosocial

# Runtime environment
FROM gcr.io/distroless/cc-debian12:debug as runtime

# Copy executable files from buildenv containers
COPY --from=h2o                       /opt              /opt
COPY --from=goreman     --chmod=0500  /goreman          /opt/bin/goreman
COPY --from=litestream  --chmod=0500  /litestream       /opt/bin/litestream
COPY --from=gotosocial  --chmod=0500  /gotosocial       /opt/bin/gotosocial 
COPY                    --chmod=0400  runtime/start.sh  /opt/bin/start

# Copy shared library from bookworm
COPY --from=buildenv-gcc /lib/x86_64-linux-gnu/libz.so.1      /lib/x86_64-linux-gnu/
COPY --from=buildenv-gcc /lib/x86_64-linux-gnu/libz.so.1.2.13 /lib/x86_64-linux-gnu/

# Copy web server assets
COPY --from=gotosocial  --chmod=0500 --chown=nobody  /web  /web
COPY                    --chmod=0500 --chown=nobody  web/  /web/

# Make to the mount directory for data
WORKDIR /data

# Copy configurations files for applications
WORKDIR /var/lib/kalaclista
COPY --chmod=0400 runtime/Procfile        /var/lib/kalaclista/Procfile
COPY --chmod=0400 runtime/gotosocial.json /var/lib/kalaclista/gotosocial.yml
COPY --chmod=0400 runtime/h2o.json        /opt/etc/h2o.conf
COPY --chmod=0400 runtime/litestream.json /etc/litestream.yml

# Application environment
FROM runtime as app

# Copy busybox as /bin/sh
COPY --from=runtime /busybox/busybox /bin/sh

# Set runtime environment variables
ENV SHELL=/busybox/sh
ENV GODEBUG=madvdontneed=1

# Set entrypoint
ENTRYPOINT ["/opt/bin/goreman", "start"]
