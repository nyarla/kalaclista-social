all:
	@echo hi,

deploy:
	flyctl deploy

build:
	docker build -t kalaclista-social .

test:
	docker run \
		--mount type=bind,source=$(shell pwd)/data,destination=/data \
		--env-file .env -p 1313:80 kalaclista-social:latest

_goremon:
	curl -L https://github.com/mattn/goreman/releases/download/v$(VERSION)/goreman_v$(VERSION)_$(OS)_$(ARCH).tar.gz \
		| tar -zxv -C tmp 
	cp tmp/goreman_v$(VERSION)_$(OS)_$(ARCH)/goreman app/bin/goreman
	rm -rf tmp/*

_caddy:
	curl -L https://github.com/caddyserver/caddy/releases/download/v$(VERSION)/caddy_$(VERSION)_$(OS)_$(ARCH).tar.gz \
		| tar -zxv -C tmp
	cp tmp/caddy app/bin/caddy
	rm -rf tmp/*

binary: \
	caddy \
	goreman

goreman:
	@$(MAKE) _goremon VERSION=0.3.13 OS=linux ARCH=amd64

caddy:
	@$(MAKE) _caddy VERSION=2.6.2 OS=linux ARCH=amd64
