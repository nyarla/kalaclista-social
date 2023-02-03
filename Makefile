all:
	@echo hi,

deploy:
	podman login -u x -p $(shell flyctl auth token) registry.fly.io/kalaclista-social
	podman build -t kalaclista-social:latest .
	podman push --format v2s2 kalaclista-social docker://registry.fly.io/kalaclista-social:latest
	flyctl deploy

build:
	podman build -t kalaclista-social .

test:
	podman run \
		--mount type=bind,source=$(shell pwd)/data,destination=/data \
		--env-file .env -p 1313:8888 kalaclista-social:latest

_litestream:
	curl -L https://github.com/benbjohnson/litestream/releases/download/v$(VERSION)/litestream-v$(VERSION)-$(OS)-$(ARCH)-static.tar.gz \
		| tar -zxv -C tmp
	cp tmp/litestream app/bin/litestream
	rm -rf tmp/*

_overmind:
	curl -L https://github.com/DarthSim/overmind/releases/download/v$(VERSION)/overmind-v$(VERSION)-$(OS)-$(ARCH).gz >tmp/overmind.gz
	cd tmp && gzip -d overmind.gz && mv overmind ../app/bin/
	chmod +x app/bin/overmind

_caddy:
	curl -L https://github.com/caddyserver/caddy/releases/download/v$(VERSION)/caddy_$(VERSION)_$(OS)_$(ARCH).tar.gz \
		| tar -zxv -C tmp
	cp tmp/caddy app/bin/caddy
	rm -rf tmp/*

binary: \
	caddy \
	overmind

litestream:
	@$(MAKE) _litestream VERSION=0.3.9 OS=linux ARCH=amd64

overmind:
	@$(MAKE) _overmind VERSION=2.4.0 OS=linux ARCH=amd64

caddy:
	@$(MAKE) _caddy VERSION=2.6.2 OS=linux ARCH=amd64
