create
    definer = rdsadmin@localhost procedure rds_rotate_general_log()
BEGIN
   DECLARE v_called_by_user VARCHAR(352);
   DECLARE v_mysql_version VARCHAR(20);
   DECLARE sql_logging BOOLEAN;
   DECLARE b_general_query_log BOOLEAN;
   SELECT @@sql_log_bin, @@general_log, user(), version() INTO sql_logging, b_general_query_log, v_called_by_user, v_mysql_version;
   
   BEGIN
     DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; SET GLOBAL general_log=b_general_query_log; RESIGNAL; END;
     SET @@sql_log_bin=OFF;
     SET GLOBAL general_log=OFF;
     DROP TABLE IF EXISTS mysql.general_log2;
     CREATE TABLE IF NOT EXISTS mysql.general_log2 LIKE mysql.general_log;
     DROP TABLE IF EXISTS mysql.general_log_backup;
     FLUSH GENERAL LOGS;
     
     
     RENAME TABLE mysql.general_log TO mysql.general_log_backup, mysql.general_log2 TO mysql.general_log;
     INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'rotate_general_log', v_mysql_version);
     COMMIT;
     SET @@sql_log_bin=sql_logging;
     SET GLOBAL general_log=b_general_query_log;
   END;
END;

