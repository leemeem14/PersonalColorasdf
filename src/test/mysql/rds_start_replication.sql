create
    definer = rdsadmin@localhost procedure rds_start_replication()
BEGIN
  CALL mysql.rds_start_replication_for_channel('');
END;

