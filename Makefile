all:
	@echo hi,

deploy:
	flyctl deploy --local-only

build:
	docker build -t kalaclista-social .

test:
	docker run \
		--mount type=bind,source=$(shell pwd)/data,destination=/data \
		--env-file .env -p 1313:80 kalaclista-social:latest

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

overmind:
	@$(MAKE) _overmind VERSION=2.3.0 OS=linux ARCH=amd64

caddy:
	@$(MAKE) _caddy VERSION=2.6.2 OS=linux ARCH=amd64
