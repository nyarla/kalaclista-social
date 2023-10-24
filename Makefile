OWNER := nyarla
REPO := gotosocial-modified
REV := 8b2948ce06abce9bf93db0a3168f8896e33e2a55
VERSION := kalaclista

all:
	@echo hi,

up: build
	env DOCKER_BUILDKIT=1 flyctl deploy -a kalaclista-social-v2 --local-only --image-label latest \
		--build-arg GITHUB_GOTOSOCIAL_OWNER=$(OWNER) \
		--build-arg GITHUB_GOTOSOCIAL_REPOSITORY=$(REPO) \
		--build-arg GITHUB_GOTOSOCIAL_REVISION=$(REV) \
		--build-arg GITHUB_GOTOSOCIAL_VERSION=$(VERSION)

build:
	nix eval --json --file src/h2o.nix >runtime/h2o.json
	nix eval --json --file src/gotosocial.nix >runtime/gotosocial.json
	nix eval --json --file src/litestream.nix >runtime/litestream.json
	env DOCKER_BUILDKIT=1 docker build -t kalaclista-social-v2_1 \
		--build-arg GITHUB_GOTOSOCIAL_OWNER=$(OWNER) \
		--build-arg GITHUB_GOTOSOCIAL_REPOSITORY=$(REPO) \
		--build-arg GITHUB_GOTOSOCIAL_REVISION=$(REV) \
		--build-arg GITHUB_GOTOSOCIAL_VERSION=$(VERSION) \
		.

pull:
	rm -rf data/sqlite3.db
	fly ssh sftp get /data/sqlite3.db data/sqlite3.db
