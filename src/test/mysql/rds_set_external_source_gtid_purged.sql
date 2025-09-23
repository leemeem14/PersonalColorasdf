create
    definer = rdsadmin@localhost procedure rds_set_external_source_gtid_purged(IN server_uuid varchar(36), IN start_pos bigint, IN end_pos bigint)
BEGIN
  DECLARE v_rdsrepl INT;
  DECLARE v_active_replication_channels INT;
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  SELECT count(1) INTO v_rdsrepl from mysql.rds_history WHERE CONVERT(action USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('disable set master' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci and CONVERT(master_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('rdsrepladmin' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  SELECT count(1) INTO v_active_replication_channels FROM performance_schema.replication_connection_status rcs JOIN performance_schema.replication_applier_status rca USING (channel_name) WHERE CONVERT(rcs.service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR CONVERT(rca.service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
        SET @@sql_log_bin=OFF;
        INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user,'set gtid_purged:ERR', v_mysql_version);
        COMMIT;
        SET @@sql_log_bin=sql_logging;
        RESIGNAL;
      END;
    SET @@sql_log_bin=OFF;
    
    INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user,'begin: set gtid_purged', v_mysql_version);
    COMMIT;
    SET @@sql_log_bin=sql_logging;
    
    
    
    IF v_rdsrepl > 0 and CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: This instance is an RDS Read Replica';
    ELSEIF CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND (CONVERT(mysql.rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR CONVERT(mysql.rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('SOURCE' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: Replication for Multi-AZ clusters is managed exclusively by RDS.';
    END IF;
    
    IF v_active_replication_channels > 0
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t modify gtid_purged because replication is already running.';
    END IF;
    IF CONVERT(server_uuid USING utf8mb4) COLLATE utf8mb4_0900_ai_ci REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' != 1
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Invalid input value for server_uuid";
    ELSEIF start_pos < 1
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Invalid input value for start_pos. The value of start_pos should be greater than or equal to 1";
    ELSEIF end_pos < start_pos
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Invalid input value for end_pos. The value of end_pos should be greater than or equal to start_pos value";
    END IF;
    
    
    SET @cmd = CONCAT("SELECT count(1) INTO @rds_external_gtid_count FROM mysql.gtid_executed 
                WHERE source_uuid='",server_uuid,"' and (",
    start_pos," BETWEEN interval_start AND interval_end 
    OR ",
    end_pos," BETWEEN interval_start AND interval_end 
    OR
    interval_start BETWEEN ",start_pos," AND ",end_pos,"
    OR
    interval_end BETWEEN ",start_pos," AND ",end_pos,")");
    PREPARE rds_external_gtid_check FROM @cmd;
    EXECUTE rds_external_gtid_check;
    DEALLOCATE PREPARE rds_external_gtid_check;
    IF CONVERT(server_uuid USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(@@GLOBAL.SERVER_UUID USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "You cannot change the GTID set belongs to the current instance";
    END IF;
    IF @rds_external_gtid_count > 0
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "The GTID set must be a superset of current @@GLOBAL.GTID_PURGED value";
    END IF;
    
    SET GLOBAL GTID_PURGED = CONCAT('+',server_uuid,':',start_pos,'-',end_pos);
    SET @@sql_log_bin=OFF;
    INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) VALUES (v_called_by_user,'set gtid_purged:OK', v_mysql_version);
    COMMIT;
    SET @@sql_log_bin=sql_logging;
  END;
END;

