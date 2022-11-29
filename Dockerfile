FROM golang:1.19.3 as builder

ENV GOPATH /go
RUN mkdir -p /go

WORKDIR /go

RUN go install github.com/superseriousbusiness/gotosocial/cmd/gotosocial@c534230600002e8ba9fefcc56908897067038dec

FROM node:16.15.1-alpine3.15 AS bundler

RUN apk add git
RUN git clone https://github.com/superseriousbusiness/gotosocial \
    && cd gotosocial \
    && git reset --hard da8954858afb4d5a3a2faf55e77d7da3be0ea3db
RUN cd gotosocial \
    && yarn install --cwd web/source \
    && BUDO_BUILD=1 node web/source \
    && rm -rf gotosocialweb/source

FROM gcr.io/distroless/python3-debian11

COPY app /app

COPY --from=builder /go/bin/gotosocial /app/bin/gotosocial
COPY --from=bundler /gotosocial/web/assets/ /app/web/public/assets/
COPY --from=bundler /gotosocial/web/template/ /app/web/template/

COPY app/web/assets/logo.png /app/web/public/assets/logo.png
COPY app/web/assets/index.tmpl /app/web/template/index.tmpl

WORKDIR /app
ENTRYPOINT ["/app/bin/goreman", "start"]
