{
  listen = { port = 9080; };

  access-log = "/dev/stdout";
  error-log = "/dev/stderr";

  compress = "ON";

  "http1-upgrade-to-http2" = "OFF";
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
      };
    };

    "kalaclista.com" = {
      paths = {
        "/" = {
          "file.dir" = "/web/www";
          "proxy.reverse.url" = "http://127.0.0.1:8080/";
          "proxy.preserve-host" = "ON";
        };

        "/api/v1/streaming" = {
          "proxy.reverse.url" = "http://127.0.0.1:8080/api/v1/streaming";
          "proxy.tunnel" = "ON";
          "proxy.connect" = [ "+127.0.0.1" "+172.16.0.0/12" ];
          "proxy.timeout.keepalive" = 0;
          "proxy.timeout.io" = 31536000;
        };

        "/fileserver" = {
          "mruby.handler-file" = "/var/run/kalaclista/mruby/fileserver.rb";
          "proxy.reverse.url" = "http://127.0.0.1:8080/fileserver";
        };
      };
    };
  };
}
