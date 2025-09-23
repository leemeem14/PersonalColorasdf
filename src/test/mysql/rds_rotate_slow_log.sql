create
    definer = rdsadmin@localhost procedure rds_rotate_slow_log()
BEGIN
   DECLARE v_called_by_user VARCHAR(352);
   DECLARE v_mysql_version VARCHAR(20);
   DECLARE sql_logging BOOLEAN;
   DECLARE b_slow_query_log BOOLEAN;
   SELECT @@sql_log_bin, @@GLOBAL.slow_query_log, user(), version() INTO sql_logging, b_slow_query_log, v_called_by_user, v_mysql_version;
   
   BEGIN
     DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; SET GLOBAL slow_query_log=b_slow_query_log; RESIGNAL; END;
     SET @@sql_log_bin=OFF;
     SET GLOBAL slow_query_log=OFF;
     DROP TABLE IF EXISTS mysql.slow_log2;
     CREATE TABLE IF NOT EXISTS mysql.slow_log2 LIKE mysql.slow_log;
     DROP TABLE IF EXISTS mysql.slow_log_backup;
     FLUSH SLOW LOGS;
     
     
     RENAME TABLE mysql.slow_log TO mysql.slow_log_backup, mysql.slow_log2 TO mysql.slow_log;
     INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'rotate_slow_log', v_mysql_version);
     COMMIT;
     SET @@sql_log_bin=sql_logging;
     SET GLOBAL slow_query_log=b_slow_query_log;
   END;
END;

