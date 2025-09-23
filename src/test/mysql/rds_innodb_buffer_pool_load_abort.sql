create
    definer = rdsadmin@localhost procedure rds_innodb_buffer_pool_load_abort()
BEGIN
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'innodb_buf_ld_abort', v_mysql_version);
    commit;
    SET GLOBAL `innodb_buffer_pool_load_abort`=1;
    SET @@sql_log_bin=sql_logging;
  END;
END;

