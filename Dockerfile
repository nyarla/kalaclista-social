FROM golang:1.19.5 as builder

ENV GOPATH /go
RUN mkdir -p /go

ARG REV

WORKDIR /go

RUN go install github.com/superseriousbusiness/gotosocial/cmd/gotosocial@$REV

FROM node:16.15.1-alpine3.15 AS bundler

ARG REV

RUN apk add git
RUN git clone https://github.com/superseriousbusiness/gotosocial \
    && cd gotosocial \
    && git reset --hard $REV
RUN cd gotosocial \
    && cd web/source \
    && yarn install \
    && BUDO_BUILD=1 node index.js \
    && cd ../../ \
    && rm -rf web/source

FROM debian:11-slim
RUN apt-get update && apt-get install -y tmux ca-certificates && rm -rf /var/lib/apt/lists/*

COPY app /app

COPY --from=builder /go/bin/gotosocial /app/bin/gotosocial

COPY --from=bundler /gotosocial/web/assets/ /app/web/public/assets/
COPY --from=bundler /gotosocial/web/template/ /app/web/template/

COPY app/web/assets/logo.png /app/web/public/assets/logo.png
COPY app/web/assets/index.tmpl /app/web/template/index.tmpl
COPY app/litestream.yaml /etc/litestream.yml

WORKDIR /app
ENTRYPOINT ["/app/bin/overmind", "start"]
