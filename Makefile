all:
	@echo hi,

pull:
	rm -rf data/sqlite3.db
	fly ssh sftp get /data/sqlite3.db data/sqlite3.db

load:
	nix-build && docker load < result

run:
	docker run -it -p 8080:8080 --rm --entrypoint /bin/sh kalaclista-social-v3:latest


up: load
	flyctl deploy -a kalaclista-social-v2 --local-only --image kalaclista-social-v3:latest --image-label latest
