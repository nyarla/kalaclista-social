{
  # general
  log-timestamp-format = "2006-01-02T15:04:05Z07:00";

  application-name = "カラクリスタ？";
  landing-page-user = "nyarla";

  host = "kalaclista.com";
  account-domain = "kalaclista.com";
  protocol = "https";
  bind-address = "127.0.0.1";
  port = 9080;

  trusted-proxies = [
    "127.0.0.1"
    "172.16.0.0/12"
  ];

  # db
  db-type = "sqlite";
  db-address = "/data/sqlite3.db";
  db-sqlite-journal-mode = "WAL";
  db-sqlite-synchronous = "NORMAL";
  cache.memory-target = "50MiB";

  # web 
  web-template-base-dir = "/web/templates";
  web-asset-base-dir = "/web/www/assets";

  # instance
  instance-languages = [ "ja" ];
  instance-inject-mastodon-version = true;
  instance-federation-spam-filter = true;

  # accounts
  accounts-registration-open = false;
  accounts-allow-custom-css = true;

  # media
  media-emoji-remote-max-size = "200KiB";
  media-remote-cache-days = 7;

  # storage
  storage-backend = "s3";
  storage-local-base-path = "/data/media";
  storage-s3-proxy = false;
  storage-s3-redirect-url = "https://gts.files.kalaclista.com";

  # http-client
  http-client = {
    timeout = "5s";
  };

  # advanced
  advanced-throttling-multiplier = 4;
  advanced-csp-extra-uris = [
    "gts.files.kalaclista.com"
  ];

  # modded version
  kalaclista-allowed-unauthorized-get = true;
  kalaclista-keep-emojis-forever = true;
}
