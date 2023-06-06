# fetch git repository
FROM alpine:edge as repo

ARG GIT_PATH
ARG GIT_REPO

RUN apk add git=2.41.0-r0 --no-cache --update && mkdir -p /go/$GIT_PATH/$GIT_REPO

ARG GIT_REV

WORKDIR /go/$GIT_PATH/$GIT_REPO
RUN   git init \
  &&  git remote add origin https://$GIT_PATH/$GIT_REPO.git \
  &&  git fetch origin $GIT_REV \
  &&  git reset --hard FETCH_HEAD

# build web frontend
FROM node:16.19.1-alpine3.17 as web

ARG GIT_PATH
ARG GIT_REPO
ARG GIT_CMD
ARG GIT_REV

COPY --from=repo /go/ /go/
WORKDIR /go/$GIT_PATH/$GIT_REPO/web/source

RUN yarn install && BUDO_BUILD=1 node index.js

WORKDIR /go/$GIT_PATH/$GIT_REPO
RUN rm -rf web/source

# build go executable binary
FROM golang:1.19.5 as bin

COPY --from=repo /go/ /go/

ARG GIT_PATH
ARG GIT_REPO
ARG GIT_CMD

WORKDIR /go/$GIT_PATH/$GIT_REPO
RUN go mod download
WORKDIR /go/$GIT_PATH/$GIT_REPO/$GIT_CMD
RUN go install .

# build runnin environment
FROM debian:11-slim

ARG GIT_PATH
ARG GIT_REPO

RUN   apt-get update  \
  &&  apt-get install -y tmux=3.1c-1+deb11u1 ca-certificates=20210119 --no-install-recommends \
  &&  rm -rf /var/lib/apt/lists/*

COPY app /app

COPY --from=bin /go/bin/gotosocial /app/bin/gotosocial 

COPY --from=web /go/$GIT_PATH/$GIT_REPO/web/assets    /app/web/public/assets/
COPY --from=web /go/$GIT_PATH/$GIT_REPO/web/template/ /app/web/template/

COPY app/web/assets/logo.png    /app/web/public/assets/logo.png
COPY app/web/assets/index.tmpl  /app/web/template/index.tmpl
COPY app/litestream.yaml        /etc/litestream.yml

ENV PATH=/app/bin:$PATH

WORKDIR /app
ENTRYPOINT ["overmind", "start"]
