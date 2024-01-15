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
          "mruby.handler" = ''
            class Redirector
              def initialize
                @cache = {}
              end

              def href(path)
                paths = path.split('/')
                paths.shift
                paths.each do |src|
                  src.gsub!(/[^a-zA-Z0-9.]+/, "")
                end

                return paths.join('/')
              end

              def call(env)
                path = href(env['PATH_INFO'])

                if cache = @cache[path]
                  return [ 302, { 'Location' => cache }, [] ]
                end

                internal = "http://127.0.0.1:8080/fileserver/#{path}"
                location = "https://media.social.src.kalaclista.com/#{path}"

                status, _, _ = http_request(internal, {
                  :method  => 'HEAD',
                  :headers => {
                    'User-Agent' => 'h2o/internal',
                  }
                }).join

                if 200 <= status && status <= 398
                  @cache[path] = location
                  return [ 302, { 'Location' => location }, [] ]
                end

                return [ 404, { 'Content-Type' => 'text/plain; charset=utf8' }, ['404 not found'] ]
              end
            end

            Redirector.new
          '';
        };
      };
    };
  };
}
