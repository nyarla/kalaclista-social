GIT_PATH := github.com/superseriousbusiness
GIT_REPO := gotosocial
GIT_CMD  := cmd/gotosocial
GIT_REV  := 282be6f26dd4dfb57c3a21b92b756c40c05b2e6c

all:
	@echo hi,

up:
	flyctl deploy -a kalaclista-social-v2 --local-only --image-label latest \
		--build-arg GIT_PATH=$(GIT_PATH) \
		--build-arg GIT_REPO=$(GIT_REPO) \
		--build-arg GIT_CMD=$(GIT_CMD) \
		--build-arg GIT_REV=$(GIT_REV)

build:
	docker build -t kalaclista-social 	\
		--build-arg GIT_PATH=$(GIT_PATH) \
		--build-arg GIT_REPO=$(GIT_REPO) \
		--build-arg GIT_CMD=$(GIT_CMD) \
		--build-arg GIT_REV=$(GIT_REV) \
		.

test:
	docker run \
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
	overmind \
	litestream

litestream:
	@$(MAKE) _litestream VERSION=0.3.9 OS=linux ARCH=amd64

overmind:
	@$(MAKE) _overmind VERSION=2.4.0 OS=linux ARCH=amd64

caddy:
	@$(MAKE) _caddy VERSION=2.6.4 OS=linux ARCH=amd64
