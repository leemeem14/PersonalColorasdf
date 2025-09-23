create
    definer = rdsadmin@localhost procedure rds_start_replication_until(IN replication_log_file text, IN replication_stop_point bigint)
BEGIN
  CALL rds_start_replication_until_for_channel(replication_log_file, replication_stop_point, '');
END;

