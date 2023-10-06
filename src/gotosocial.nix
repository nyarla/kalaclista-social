{
  # application
  application-name = "カラクリスタ？";
  landing-page-user = "nyarla";

  # host
  host = "kalaclista.com";
  account-domain = "kalaclista.com";
  protocol = "https";
  bind-address = "127.0.0.1";
  port = 8080;

  # let's encrypt
  letsencrypt-enabled = false;

  # db
  db-type = "sqlite";
  db-address = "/data/sqlite3.db";
  db-sqlite-journal-mode = "WAL";
  db-sqlite-synchronous = "NORMAL";

  # web 
  web-template-base-dir = "/web/templates";
  web-asset-base-dir = "/web/www";

  # gotosocial
  accounts-registration-open = false;
  accounts-allow-custom-css = true;

  storage-backend = "s3";
  storage-s3-proxy = true;

  trusted-proxies = [ "127.0.0.1" "172.16.0.0/12" ];

  # modded version
  kalaclista-allowed-unauthorized-get = true;
}
