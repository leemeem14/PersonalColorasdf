create
    definer = rdsadmin@localhost procedure rds_start_upgrade_prechecks(IN targetEngineName text, IN targetEngineVersion text)
BEGIN
  DECLARE v_engine_version TEXT;
  DECLARE v_called_by_user TEXT;
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

    
    INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user, 'start prechecks', v_engine_version);
    COMMIT;

    SELECT action, status INTO most_recent_action, most_recent_status FROM mysql.rds_upgrade_prechecks ORDER BY id DESC LIMIT 1;

    
    IF CONVERT(targetEngineName USING utf8mb4) COLLATE utf8mb4_0900_ai_ci <> CONVERT('mysql' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR targetEngineName IS NULL
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only mysql target engine is supported';
    END IF;

    
    IF targetEngineVersion IS NULL OR CONVERT(targetEngineVersion USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Target engine version is required';
    
    ELSEIF NOT CONVERT(targetEngineVersion USING utf8mb4) COLLATE utf8mb4_0900_ai_ci REGEXP '^(5\.7\.[0-9]{1,2}|8\.[0-4]\.[0-9]{1,2}|9\.[0-9]\.[0-9]{1,2}|10\.[0-9]\.[0-9]{1,2})$'
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Provide valid engine version which must be supported RDS for MySQL version in X.Y.Z format';
    END IF;

    IF most_recent_action = CONVERT('engine upgrade' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND most_recent_status IN (CONVERT('in progress' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot call procedure while engine upgrade in progress.';
    ELSEIF most_recent_action = CONVERT('start_precheck' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND most_recent_status IN (CONVERT('in progress' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci,CONVERT('pending' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Upgrade prechecks in progress. Please stop currently running prechecks using mysql.rds_stop_upgrade_prechecks()';
    ELSE
      INSERT INTO mysql.rds_upgrade_prechecks(action,status,engine_version,target_engine_name,target_engine_version) VALUES (CONVERT('start_precheck' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('pending' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT(v_engine_version USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, targetEngineName, targetEngineVersion);
      
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user, 'start prechecks:ok', v_engine_version);
      COMMIT;
      SELECT 'Starting upgrade prechecks.' as 'Success';
    END IF;
    SET @@sql_log_bin=sql_logging;
    SET GLOBAL admin_tls_version=default;
END;

END;

