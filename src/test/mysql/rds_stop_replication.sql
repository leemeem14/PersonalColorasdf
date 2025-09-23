create
    definer = rdsadmin@localhost procedure rds_stop_replication()
BEGIN
  CALL mysql.rds_stop_replication_for_channel('');
END;

