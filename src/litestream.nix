{
  dbs = [{
    path = "/data/sqlite3.db";
    replicas = [{
      type = "s3";
      bucket = "kalaclista-social-backup";
      path = "sqlite3";
      endpoint = "\${LITESTREAM_S3_ENDPOINT}";
    }];
  }];
}
