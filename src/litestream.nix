{
  dbs = [
    {
      path = "/data/sqlite3.db";
      replicas = [
        {
          url = "\${LITESTREAM_R2_URL}";
          endpoint = "\${LITESTREAM_R2_ENDPOINT}";
        }
      ];
    }
  ];
}
