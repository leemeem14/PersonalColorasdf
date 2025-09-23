create
    definer = rdsadmin@localhost procedure rds_start_replication_until_gtid(IN gtid text)
BEGIN
  CALL mysql.rds_start_replication_until_gtid_for_channel(gtid, '');
END;

