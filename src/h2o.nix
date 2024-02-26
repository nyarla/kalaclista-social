{
  listen = { port = 8080; };

  access-log = "/dev/stdout";
  error-log = "/dev/stderr";

  compress = "ON";

  "proxy.preserve-x-forwarded-proto" = "ON";

  hosts = {
    "kalaclista-social-v2.fly.dev" = {
      paths = {
        "/" = {
          redirect = {
            status = 308;
            url = "https://kalaclista.com";
          };
        };
        "/.well-known/healthcheck" = {
          "mruby.handler" = ''
            lambda do |env|
              return [ 200, {'Content-Type' => 'text/plain'}, ['ok'] ]
            end
          '';
        };
      };
    };

    "kalaclista.com" = {
      paths = {
        "/" = {
          "file.dir" = "/web/www";
          "proxy.reverse.url" = "http://127.0.0.1:9080/";
          "proxy.preserve-host" = "ON";
        };

        "/api/v1/streaming" = {
          "proxy.reverse.url" = "http://127.0.0.1:9080/api/v1/streaming";
          "proxy.tunnel" = "ON";
          "proxy.connect" = [ "+127.0.0.1" "+172.16.0.0/12" ];
          "proxy.timeout.keepalive" = 0;
          "proxy.timeout.io" = 31536000;
        };

        "/fileserver" = {
          "file.dir" = "/data/media";
          "proxy.reverse.url" = "http://127.0.0.1:9080/fileserver";
        };
      };
    };
  };
}
