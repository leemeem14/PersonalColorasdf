create
    definer = rdsadmin@localhost procedure rds_start_replication_until_gtid_for_channel(IN gtid text, IN channel varchar(64))
BEGIN
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_service_state_for_channel ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_replica_parallel_workers INT;
  DECLARE sql_logging BOOLEAN;
  DECLARE skip_repl_error INT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_service_state_for_channel;
  SELECT @@replica_parallel_workers into v_replica_parallel_workers;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_gtid) VALUES(v_called_by_user, 'Starting: start slave until', v_mysql_version, gtid);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_gtid) VALUES(v_called_by_user, 'Starting: start channel until', v_mysql_version, gtid);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SET @message_text = CONCAT('You can''t start replication because the replica isn''t configured. First call mysql.rds_set_external_master.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    ELSE
      SET @message_text = CONCAT('The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci in (CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  , CONVERT('BROKEN' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  )
  THEN
    
    
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication may already be running. Call rds_stop_replication to stop replication';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication may already be running. Call rds_stop_replication_for_channel to stop replication.';
    END IF;
  ELSEIF v_replica_parallel_workers > 1 THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rds_start_replication_until_gtid is not supported for multi-threaded slaves';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rds_start_replication_until_gtid_for_channel is not supported for multi-threaded replicas.';
    END IF;
  ELSEIF gtid IS NULL THEN
    
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid input: gtid cannot be NULL';
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    
    
    SELECT @@global.sql_replica_skip_counter INTO skip_repl_error;
    IF skip_repl_error > 0
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another session currently running the procedure mysql.rds_skip_repl_error_for_channel. Consider to retry the procedure call.';
    END IF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      UPDATE mysql.rds_replication_status SET called_by_user = v_called_by_user, action = 'start slave until', mysql_version = v_mysql_version, replication_gtid = gtid, replication_log_file = NULL, replication_stop_point = NULL WHERE action IS NOT NULL AND (CONVERT(channel_name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR channel_name IS NULL);
      COMMIT;
    ELSE
      UPDATE mysql.rds_replication_status SET called_by_user = v_called_by_user, action = 'start channel until', mysql_version = v_mysql_version, replication_gtid = gtid, replication_log_file = NULL, replication_stop_point = NULL WHERE action IS NOT NULL AND CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
    END IF;
    
    SET @cmd = CONCAT('START REPLICA UNTIL SQL_AFTER_GTIDS = ', QUOTE(gtid), ' FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_start_replication_for_channel_until FROM @cmd;
    EXECUTE rds_start_replication_for_channel_until;
    DEALLOCATE PREPARE rds_start_replication_for_channel_until;
    DO SLEEP(2);
    SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_service_state_for_channel;
    IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_gtid) VALUES(v_called_by_user, 'start slave until', v_mysql_version, gtid);
        COMMIT;
        SELECT CONCAT('Replication started until SQL_AFTER_GTIDS = ', QUOTE(gtid)) AS Message;
      ELSE
        INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_gtid) VALUES(v_called_by_user, 'start channel until', v_mysql_version, gtid);
        COMMIT;
        SELECT CONCAT('Replication started until SQL_AFTER_GTIDS = ', QUOTE(gtid), ' for channel ', QUOTE(TRIM(BOTH FROM channel))) AS Message;
      END IF;
    ELSE
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered an error. Run SHOW SLAVE STATUS\\G; to see the error.';
      ELSE
        SET @error_message = CONCAT('Replication for specified channel encountered an error. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
      END IF;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

