FROM golang:1.19.5 as builder

ENV GOPATH /go
RUN mkdir -p /go
ENV REV b4d18887d3deec8556f8b2de2369a768df01eb29

WORKDIR /go

RUN go install github.com/superseriousbusiness/gotosocial/cmd/gotosocial@$REV

FROM node:16.15.1-alpine3.15 AS bundler

RUN apk add git
RUN git clone https://github.com/superseriousbusiness/gotosocial \
    && cd gotosocial \
    && git reset --hard $REV
RUN cd gotosocial \
    && yarn install --cwd web/source \
    && BUDO_BUILD=1 node web/source \
    && rm -rf gotosocialweb/source

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
