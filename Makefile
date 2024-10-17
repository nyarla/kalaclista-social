OWNER := nyarla
REPO := gotosocial-modded
REV := 73e1dd31670443779c3787ea919a8be26b935550
VERSION := kalaclista

all:
	@echo hi,

up: build
	env DOCKER_BUILDKIT=1 flyctl deploy -a kalaclista-social-v2 --local-only --image-label latest \
		--build-arg GITHUB_GOTOSOCIAL_OWNER=$(OWNER) \
		--build-arg GITHUB_GOTOSOCIAL_REPOSITORY=$(REPO) \
		--build-arg GITHUB_GOTOSOCIAL_REVISION=$(REV) \
		--build-arg GITHUB_GOTOSOCIAL_VERSION=$(VERSION)

config: blocklist
	nix eval --json --file src/h2o.nix >runtime/h2o.json
	nix eval --json --file src/gotosocial.nix >runtime/gotosocial.json
	nix eval --json --file src/litestream.nix >runtime/litestream.json

build: config
	env DOCKER_BUILDKIT=1 docker build -t kalaclista-social-v2_1 \
		$(EXTRA_BUILD_ARGS) \
		--build-arg GITHUB_GOTOSOCIAL_OWNER=$(OWNER) \
		--build-arg GITHUB_GOTOSOCIAL_REPOSITORY=$(REPO) \
		--build-arg GITHUB_GOTOSOCIAL_REVISION=$(REV) \
		--build-arg GITHUB_GOTOSOCIAL_VERSION=$(VERSION) \
		.

rebuild:
	@$(MAKE) EXTRA_BUILD_ARGS="--no-cache" build

pull:
	rm -rf data/sqlite3.db
	fly ssh sftp get /data/sqlite3.db data/sqlite3.db

test:
	docker run -it -p 8080:8080 --rm --entrypoint /busybox/sh kalaclista-social-v2_1:latest

blocklist:
	test -e src/tor.block || curl -L 'https://check.torproject.org/torbulkexitlist' | tr "\n" " " >src/tor.block
