kalaclista-social
=================

The deployment toolkit to fly.io with shoreman, litestream, h2o and gotosocial for my fediverse instance.

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
- `GITHUB_*_REPOSITORY` - The repository name on GitHub
- `GITHUB_*_REVISION` - The hash value of revision on the git repository
- `GITHUB_*_VERSION`- This value exists for metadata, but is not always

As current exists:

```
GITHUB_SHOREMAN_URL="https://raw.githubusercontent.com/chrismytton/shoreman/master/shoreman.sh"
GITHUB_SHOREMAN_SHA256="a21acce3072bb8594565094e4a9bbafd3b9d7fa04abd7e0c74c19fd479adb817"

GITHUB_LITESTREAM_OWNER=benbjohnson
GITHUB_LITESTREAM_REPOSITORY=litestream
GITHUB_LITESTREAM_REVISION=94f69a0eb32a9a23571f0cd88dcfc9c32ddd426f
GITHUB_LITESTREAM_VERSION=git

GITHUB_H2O_OWNER=h2o
GITHUB_H2O_REPOSITORY=h2o
GITHUB_H2O_REVISION=7545f5fe55ccdc9a12bdeb246b5d7110f8bee225

GITHUB_GOTOSOCIAL_OWNER=superseriousbusiness
GITHUB_GOTOSOCIAL_REPOSITORY=gotosocial
GITHUB_GOTOSOCIAL_REVISION=0bd95d7b71ae71d801b0fbb643598eb0ccd1b8f5
GITHUB_GOTOSOCIAL_VERSION=v0.14.2
```

If you would to find more details, please looking at [Dockerfile](Dockerfile) or [Makefile](Makefile).

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

If you would to use these files your instance, please rewrite to yours.

## Licenses

This repository excepts some files, is under the [AGPL](LICENSE).

Excepts files are as:

- [web/www/logo.png](web/www/logo.png)
  - this file is the my avatar icon, and all rights reserved.
- [web/www/ads.txt](web/www/ads.txt)
  - this file is metadata file for google adsense on my website. you chould not use.

## Author

OKAMURA Naoki aka nyarla [@nyarla@kalaclista.com](https://kalaclista.com/@nyarla)
