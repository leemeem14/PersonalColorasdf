create
    definer = rdsadmin@localhost procedure rds_rotate_global_status_history()
BEGIN
  DECLARE sql_logging BOOLEAN;
  select @@sql_log_bin into sql_logging;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    drop table mysql.rds_global_status_history_old;
    rename table mysql.rds_global_status_history to mysql.rds_global_status_history_old;
    create table mysql.rds_global_status_history like mysql.rds_global_status_history_old;
    SET @@sql_log_bin=sql_logging;
  END;
END;

