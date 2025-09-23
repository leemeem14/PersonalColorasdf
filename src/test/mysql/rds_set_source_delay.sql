create
    definer = rdsadmin@localhost procedure rds_set_source_delay(IN delay int)
BEGIN
  CALL mysql.rds_set_source_delay_for_channel(delay, '');
END;

