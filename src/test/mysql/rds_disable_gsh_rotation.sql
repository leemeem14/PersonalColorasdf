create
    definer = rdsadmin@localhost procedure rds_disable_gsh_rotation()
begin
  DECLARE sql_logging BOOLEAN;
  select @@sql_log_bin into sql_logging;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    alter event ev_rds_gsh_table_rotation DISABLE;
    select 'Table Rotation Disabled' as `Success`;
    SET @@sql_log_bin=sql_logging;
  END;
end;

