create
    definer = rdsadmin@localhost procedure rds_next_master_log(IN curr_master_log int)
BEGIN
  CALL mysql.rds_next_source_log_for_channel(curr_master_log, '');
END;

