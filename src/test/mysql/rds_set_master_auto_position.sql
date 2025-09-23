create
    definer = rdsadmin@localhost procedure rds_set_master_auto_position(IN auto_position_mode tinyint(1))
BEGIN
  CALL mysql.rds_set_source_auto_position_for_channel(auto_position_mode, '');
END;

