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

  trusted-proxies = [ "127.0.0.1" "172.16.0.0/12" ];

  # db
  db-type = "sqlite";
  db-address = "/data/sqlite3.db";
  db-sqlite-journal-mode = "WAL";
  db-sqlite-synchronous = "NORMAL";

  # web 
  web-template-base-dir = "/web/templates";
  web-asset-base-dir = "/web/www";

  # instance
  instance-languages = [ "ja" ];
  instance-inject-mastodon-version = true;

  # accounts
  accounts-registration-open = false;
  accounts-allow-custom-css = false;

  # media
  media-remote-cache-days = 0;

  # storage
  storage-backend = "s3";
  storage-s3-proxy = true;
  storage-local-base-path = "/data/media";

  # http-client
  http-client = { timeout = "5s"; };

  # modded version
  kalaclista-allowed-unauthorized-get = true;
}
