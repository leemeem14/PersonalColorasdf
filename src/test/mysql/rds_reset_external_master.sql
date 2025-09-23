create
    definer = rdsadmin@localhost procedure rds_reset_external_master()
BEGIN
  CALL mysql.rds_reset_external_source_for_channel('');
END;

