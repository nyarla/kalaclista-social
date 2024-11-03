{
  pkgs ? import <nixpkgs> { },
}:

with pkgs;

let
  apps =
    let
      go = {
        ldflags = [
          "-s"
          "-w"
          "-linkmode 'external'"
          "-extldflags '-static'"
        ];

        tags = [
          "osusergo"
          "netgo"
        ];
      };

      src = fetchFromGitHub {
        owner = "nyarla";
        repo = "gotosocial-modded";
        rev = "73e1dd31670443779c3787ea919a8be26b935550";
        hash = "sha256-6+/Hc/eTW0F/DpViIW7oVVeC3v0ARt+zQSx+r5JlpF4=";
      };
    in
    {
      inherit src;

      shoreman = pkgs.writeScriptBin "shoreman" (
        builtins.readFile (fetchurl {
          url = "https://raw.githubusercontent.com/chrismytton/shoreman/f9687d6663074f747a29f6dcf0d392c2d39c425a/shoreman.sh";
          sha256 = "05xqmmwx97y1fh67xgaal1zrsfzxpadllkh9cm2mkf1b0ziwq6m2";
        })
      );

      litestream = pkgsMusl.buildGo123Module rec {
        pname = "litestream";
        version = "git";
        src = fetchFromGitHub {
          owner = "benbjohnson";
          repo = "litestream";
          rev = "2f22a4babf8bc19712b23bbb31d0ef6020cf78b0";
          hash = "sha256-ZJFdWsqILyoNX1/hbX19HmMVdgFCxAN52wL+bcsQcJs=";
        };

        vendorHash = "sha256-PlfDJbhzbH/ZgtQ35KcB6HtPEDTDgss7Lv8BcKT/Dgg=";

        ldflags = go.ldflags ++ [
          "-X main.Version=${src.rev}"
        ];

        tags = go.tags ++ [
          "sqlite_omit_load_extension"
        ];

        subPackages = [
          "cmd/litestream"
        ];
      };

      caddyserver = pkgsMusl.buildGo123Module {
        pname = "caddyserver";
        version = "v2.8.4";
        src = fetchFromGitHub {
          owner = "caddyserver";
          repo = "caddy";
          rev = "7088605cc11c52c2777ab613dfc5c2a9816006e4";
          hash = "sha256-CBfyqtWp3gYsYwaIxbfXO3AYaBiM7LutLC7uZgYXfkQ=";
        };

        vendorHash = "sha256-1Api8bBZJ1/oYk4ZGIiwWCSraLzK9L+hsKXkFtk6iVM=";

        inherit (go) ldflags;

        tags = go.tags ++ [
          "nobadger"
          "nomysql"
          "nopgx"
        ];

        subPackages = [
          "cmd/caddy"
        ];
      };

      gotosocial = pkgsMusl.buildGo122Module rec {
        pname = "gotosocial";
        version = "kalaclista-v0.17.0";
        inherit src;

        vendorHash = null;

        subPackages = [
          "cmd/gotosocial"
        ];

        ldflags = go.ldflags ++ [
          "-X main.Version=${version}"
        ];

        tags = go.tags ++ [
          "static_build"
          "kvformat"
          "timetzdata"
          "notracing"
          "nometric"
        ];
      };

      web =
        let
          websrc = pkgs.runCommand "web" { } ''
            mkdir -p $out/
            cp -r ${src}/web/source/* $out/
          '';
        in
        pkgs.mkYarnPackage {
          pname = "gotosocial-web";
          inherit (gotosocial) version;
          src = websrc;

          packageJSON = websrc + /package.json;
          offlineCache = pkgs.fetchYarnDeps {
            yarnLock = websrc + /yarn.lock;
            hash = "sha256-quAAjbF/xBhmyy7DOnOZ8fuhJGcmgIXdJh/gVsQm4Fk=";
          };

          buildPhase = ''
            runHook preBuild

            yarn --offline ts-patch install
            yarn --offline build

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/
            cp -r deps/assets/dist/* $out/

            runHook postInstall
          '';

          doDist = false;
        };

      busybox = pkgsMusl.busybox.override {
        enableStatic = true;
      };

      inherit (pkgsMusl) bash;
    };
in

dockerTools.buildImage rec {
  name = "kalaclista-social-v3";
  tag = "latest";

  copyToRoot = pkgsMusl.buildEnv {
    inherit name;

    paths =
      (with apps; [
        bash
        busybox
        caddyserver
        gotosocial
        litestream
        shoreman
      ])
      ++ [
        cacert
      ];

    pathsToLink = [
      "/bin"
      "/etc"
    ];

    postBuild =
      let
        files = {
          gotosocial = pkgs.writeText "gotosocial.json" (builtins.toJSON (import ./src/gotosocial.nix));
          litestream = pkgs.writeText "litestream.json" (builtins.toJSON (import ./src/litestream.nix));
          passwd = pkgs.writeText "passwd" ''
            root:x:0:0:root:/root:/sbin/nologin
            nobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin
          '';
          group = pkgs.writeText "group" ''
            root:x:0:
            nobody:x:65534:
            tty:x:5:
          '';
          procfile = pkgs.writeText "Procfile" ''
            caddy: sh -c 'while true; do env GOMEMLIMIT=40MiB caddy run -c Caddyfile ; done'
            gotosocial: sh -c 'while true; do env GOMEMLIMIT=256MiB GTS_WAZERO_COMPILATION_CACHE=/data/.wasm gotosocial --config-path gotosocial.yaml server start ; done'
            litestream: sh -c 'while true; do env GOMEMLIMIT=60MiB litestream replicate -config litestream.yaml ; done'
          '';

          caddyfile = pkgs.writeText "Caddyfile" ''
            {
              auto_https off
            }

            http://kalaclista-social-v3.fly.dev:8080 {
              redir https://kalaclista.com
            }

            http://kalaclista.com:8080, http://localhost:8080 {
              root * /web/www

              @exists file
              handle @exists {
                header /.well-known/nostr.json Access-Control-Allow-Origin "*"
                file_server 
              }

              reverse_proxy http://127.0.0.1:9080 {
                header_up X-Forwarded-For {http.request.header.FLY-CLIENT-IP}
                flush_interval -1
              }
            }

          '';
        };
      in
      ''
        # copy configuration files to contianer
        mkdir -p $out/var/lib/kalaclista

        cp ${files.gotosocial} $out/var/lib/kalaclista/gotosocial.yaml
        cp ${files.litestream} $out/var/lib/kalaclista/litestream.yaml

        cp ${files.procfile} $out/var/lib/kalaclista/Procfile
        cp ${files.caddyfile} $out/var/lib/kalaclista/Caddyfile

        # copy assets files to container
        mkdir -p $out/web/www

        cp -r ${apps.src}/web/template $out/web/templates

        cp -r ${apps.src}/web/assets $out/web/www/assets
        chmod +w $out/web/www/assets

        cp -r ${apps.web} $out/web/www/assets/dist
        cp -r ${./web/www/root}/* $out/web/www/
        cp -r ${./web/www/root}/.* $out/web/www/

        # mount dir
        mkdir -p $out/data

        # system files or directories
        chmod +w $out/etc
        cp ${files.passwd} $out/etc/passwd
        cp ${files.group}  $out/etc/group

        mkdir -p $out/tmp
      '';
  };

  config = {
    Env = [
      "PATH=/bin"
    ];
    WorkingDir = "/var/lib/kalaclista";
    Entrypoint = [
      "shoreman"
    ];
  };
}
