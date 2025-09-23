create
    definer = rdsadmin@localhost procedure rds_skip_transaction_with_gtid(IN gtid_to_skip text)
BEGIN
  DECLARE v_threads_running int;
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET GTID_NEXT=gtid_to_skip;
    START TRANSACTION;
    COMMIT;
    SET GTID_NEXT="AUTOMATIC";
    Select 'Transaction has been skipped successfully.' as Message;
    set @@sql_log_bin=off; 
    INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'rds_skip_transaction_with_gtid:OK',v_mysql_version);
    commit;
    SET @@sql_log_bin=sql_logging;
  END;
END;

