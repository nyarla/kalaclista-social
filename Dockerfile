# fetch git repository
FROM alpine:edge as src

RUN apk add git=2.41.0-r2 --no-cache --update && mkdir -p /go/$GIT_PATH/$GIT_REPO
RUN mkdir -p /build

WORKDIR /build

ARG GIT_PATH
ARG GIT_REPO
ARG GIT_REV

RUN git init \
  && git remote add origin https://$GIT_PATH/$GIT_REPO.git \
  && git fetch --depth 1 origin $GIT_REV \
  && git reset --hard $GIT_REV \
  && rm -rf .git

# build web frontend
FROM node:16.19.1-alpine3.17 as web
COPY --from=src /build/web /build/web/

WORKDIR /build/web
RUN cd source \
  && yarn install \
  && BUDO_BUILD=1 node index.js \
  && cd .. \
  && rm -rf source

# build go executable binary
FROM golang:1.19.5 as binary

ARG GIT_REV

RUN mkdir -p /build
WORKDIR /build

COPY --from=src /build /build/

RUN go mod download \
  && VERSION=kalaclista-"$(echo "$GIT_REV" | cut -c 1-7)" ./scripts/build.sh

# build runnin environment
FROM debian:11-slim

RUN   apt-get update  \
  &&  apt-get install -y tmux=3.1c-1+deb11u1 ca-certificates=20210119 --no-install-recommends \
  &&  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app
WORKDIR /app

COPY app .
COPY --from=binary /build/gotosocial /app/bin/gotosocial
COPY --from=web /build/web/assets /app/web/public/assets/
COPY --from=web /build/web/template /app/web/template/

COPY app/web/assets/logo.png    /app/web/public/assets/logo.png
COPY app/litestream.yaml        /etc/litestream.yml

ENV PATH=/app/bin:$PATH

ENTRYPOINT ["overmind", "start"]
