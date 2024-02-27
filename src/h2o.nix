let
  tor = builtins.readFile ./tor.block;

  acl = ''
    TOR = %w(${tor})

    FORBIDDEN = [ 403, {}, [] ]
    NEXT = [ 399, {}, [] ]

    lambda do |env|
      if TOR.include?(env['HTTP_FLY_CLIENT_IP'])
        return FORBIDDEN
      end

      if /\/store.lock/.match(env['PATH_INFO'])
        return FORBIDDEN
      end

      return NEXT
    end
  '';

  rewrite = ''
    lambda do |env|
      env['HTTP_X_FORWARDED_FOR'] = env['HTTP_FLY_CLIENT_IP']

      return H2O.next.call(env)
    end
  '';

  proxy = ''
    ENDPOINT  = "https://media.social.src.kalaclista.com"
    LOCALPATH = "/data/exists"

    def fn(path)
      return "#{LOCALPATH}/#{path.gsub('/', '.')}"
    end

    def check(path)
      return File.exist?(path)
    end

    def fetch(env)
      headers = {}
      env.each do |key, value|
        if /^HTTP_/.match(key)
          headers[$'] = value
        end
      end

      href = "#{ENDPOINT}#{env['PATH_INFO']}"
      body = env['rack.input'] ? env['rack.input'].read : "";

      return http_request(href, {
        :method => env['REQUEST_METHOD'],
        :header => headers,
        :body   => body,
      }).join
    end

    lambda do |env|
      path = fn(env['PATH_INFO'])

      if check(path)
        return fetch(env)
      end

      response = H2O.next.call(env)
      if 200 <= response[0] && response[0] <= 299
        fh = File.open(path, 'w')
        fh.close()
      end

      return response
    end
  '';
in {
  listen = { port = 8080; };

  access-log = "/dev/stdout";
  error-log = "/dev/stderr";

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
      paths = let upstream = "http://127.0.0.1:9080";
      in {
        "/" = [
          { "mruby.handler" = acl; }
          { "mruby.handler" = rewrite; }
          {
            "file.dir" = "/web/www";
            "proxy.reverse.url" = "${upstream}/";
            "proxy.preserve-host" = "ON";
          }
        ];

        "/api/v1/streaming" = [
          { "mruby.handler" = acl; }
          { "mruby.handler" = rewrite; }
          {
            "proxy.reverse.url" = "${upstream}/api/v1/streaming";
            "proxy.tunnel" = "ON";
            "proxy.connect" = [ "+127.0.0.1" "+172.16.0.0/12" ];
            "proxy.timeout.keepalive" = 0;
            "proxy.timeout.io" = 31536000;
          }
        ];

        "/fileserver" = [
          { "mruby.handler" = acl; }
          { "mruby.handler" = rewrite; }
          { "mruby.handler" = proxy; }
          { "proxy.reverse.url" = "${upstream}/fileserver"; }
        ];
      };
    };
  };
}
