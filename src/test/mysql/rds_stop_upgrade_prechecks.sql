create
    definer = rdsadmin@localhost procedure rds_stop_upgrade_prechecks()
BEGIN
  DECLARE v_called_by_user TEXT;
  DECLARE v_engine_version TEXT;
  DECLARE most_recent_action TEXT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
  DECLARE most_recent_status TEXT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
  DECLARE sql_logging BOOLEAN;

SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_engine_version;

BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; SET GLOBAL admin_tls_version=default; RESIGNAL; END;
    SET @@sql_log_bin=OFF;

    
    
    
    
    
    
    
    IF CONVERT(substring_index(version(),'.',2) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('8.0' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND substring(version(),5,6) <= 35
    THEN
        SET GLOBAL admin_tls_version='TLSv1.3';
    END IF;

    
    INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user, 'stop prechecks', v_engine_version);
    COMMIT;

    SELECT action, status INTO most_recent_action, most_recent_status FROM mysql.rds_upgrade_prechecks ORDER BY id DESC LIMIT  1;

    IF most_recent_action = CONVERT('engine upgrade' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND most_recent_status IN (CONVERT('pending' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('in progress' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot call procedure while engine upgrade in progress.';
    ELSEIF most_recent_action = CONVERT('stop_precheck' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR most_recent_status IN (CONVERT('stopped' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('unable to be completed' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('prechecks failed' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('prechecks passed' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot call procedure, upgrade prechecks not running.';
    ELSE
      
      UPDATE mysql.rds_upgrade_prechecks SET STATUS=CONVERT('stopping' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci WHERE CONVERT(status USING utf8mb4) COLLATE utf8mb4_0900_ai_ci IN (CONVERT('pending' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('in progress' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci);
      
      INSERT INTO mysql.rds_upgrade_prechecks(action, status) VALUES (CONVERT('stop_precheck' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci,CONVERT('stopping' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci);
      
      INSERT INTO mysql.rds_history(called_by_user,action,mysql_version) VALUES (v_called_by_user,'stop prechecks:ok',v_engine_version);
      COMMIT;
      SELECT 'Stopping upgrade prechecks.' as `Success`;
    END IF;

    SET @@sql_log_bin=sql_logging;
    SET GLOBAL admin_tls_version=default;
END;

END;

