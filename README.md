kalaclista-social
=================

the deployment toolkit to fly.io with hivemind, litestream, h2o and gotosocial for my fediverse instance.

## How to using that

### Building to the container

You could build the docker container as these commands:

```bash
# generates the software configurations.
# thses commands requires `nix` with experimental features. 
$ nix eval --json --file src/h2o.nix >runtime/h2o.json
$ nix eval --json --file src/gotosocial.nix >runtime/gotosocial.json
$ nix eval --json --file src/litestream.nix >runtime/litestream.json

# build to the docker container
$ docker build -t kalaclista-social-v2_1 .
```

You could customize these softwares owners, repositories, revisions or versions by the build args:

Naming rules as:

- `GITHUB_*_OWNER` - The repository owner on GitHub
- `GITHUB_*_REPOSITORY` - The repository name on GITHUB
- `GITHUB_*_REVISION` - The hash value of revision on the git repository
- `GITHUB_*_VERSION`- This value exists for metadata, but is not always

As current exists:

```
GITHUB_HIVEMIND_OWNER=DarthSim
GITHUB_HIVEMIND_REPOSITORY=hivemind
GITHUB_HIVEMIND_REVISION=580abe5b3faf585c450604227e40e960cdbb21bd

GITHUB_LITESTREAM_OWNER=benbjohnson
GITHUB_LITESTREAM_REPOSITORY=litestream
GITHUB_LITESTREAM_REVISION=e0493f979a8269a53b83b35939d0820f0a3a4fc1
GITHUB_LITESTREAM_VERSION=v0.3.11

GITHUB_H2O_OWNER=h2o
GITHUB_H2O_REPOSITORY=h2o
GITHUB_H2O_REVISION=cb9f500d0854b167862b3c599e4b89212d66c5c6

GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
GITHUB_GOTOSOCIAL_REVISION=c7a46e05dbca86b30123cb1c45c1457bbc7a9c4b
GITHUB_GOTOSOCIAL_VERSION=v0.11.1
```

If you would to find more details, please looking at <Dockerfile> or <Makefile>.

## Running to this container

For working this container, you need to define the these environment variables by any methods:

```
GTS_STORAGE_S3_ENDPOINT=
GTS_STORAGE_S3_ACCESS_KEY=
GTS_STORAGE_S3_SECRET_KEY=
GTS_STORAGE_S3_BUCKET=
GTS_SMTP_HOST=
GTS_SMTP_PORT=
GTS_SMTP_USERNAME=
GTS_SMTP_PASSWORD=
GTS_SMTP_FROM=
LITESTREAM_ACCESS_KEY_ID=
LITESTREAM_SECRET_ACCESS_KEY=
LITESTREAM_S3_ENDPOINT=
```

These environment variables requires by [gotosocial](https://docs.gotosocial.org) or [litestream](https://litestream.io),
and you would to find more details, you could by their documentations. 

## Notice

The files of `src/*.nix` or `fly.tonl` is for my instance.

If you would to use these files your instance, please rewrite by yours.

## Licenses

This repository excepts some files is under the [AGPL](LICENSE)

Excepts files are as:

- <web/logo.png>
  - this file is the my avatar icon, and all rights reserved.
- <web/ads.txt>
  - this file is metadata file for google adsense on my website. you chould not use.

## Author

OKAMURA Naoki aka nyarla [@nyarla@kalaclista.com](https://kalaclista.com/@nyarla)
