create
    definer = rdsadmin@localhost procedure rds_set_source_auto_position_for_channel(IN auto_position_mode tinyint(1), IN channel varchar(64))
BEGIN
  DECLARE v_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_channel_service_state;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT into mysql.rds_history(called_by_user, action, mysql_version, auto_position) values (v_called_by_user,'Starting: set_master_AP', v_mysql_version, auto_position_mode);
      COMMIT;
    ELSE
      INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'Starting: set_channel_AP',v_mysql_version);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SET @message_text = CONCAT('You can''t modify auto_position mode because the replica isn''t configured. First call mysql.rds_set_external_master.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    ELSE
      SET @message_text = CONCAT('The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  END IF;
  
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET @cmd = CONCAT('STOP REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_stop_replica_for_channel FROM @cmd;
    EXECUTE rds_stop_replica_for_channel;
    DEALLOCATE PREPARE rds_stop_replica_for_channel;
    
    SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO SOURCE_AUTO_POSITION = ', auto_position_mode,
                       ' FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_set_source_for_channel FROM @cmd;
    EXECUTE rds_set_source_for_channel;
    DEALLOCATE PREPARE rds_set_source_for_channel;
    SET @cmd = CONCAT('START REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_start_replica_for_channel FROM @cmd;
    EXECUTE rds_start_replica_for_channel;
    DEALLOCATE PREPARE rds_start_replica_for_channel;
    DO SLEEP(2);
    SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_channel_service_state;
    IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SELECT CONCAT('Master Auto Position has been set to ', auto_position_mode,'.') AS Message;
        SELECT 'Slave is running normally' as Message;
        INSERT into mysql.rds_history(called_by_user, action, mysql_version, auto_position) values (v_called_by_user,'set_master_AP:OK', v_mysql_version, auto_position_mode);
        COMMIT;
      ELSE
        SELECT CONCAT('Source Auto Position has been set to ', auto_position_mode,' for channel ', QUOTE(TRIM(BOTH FROM channel)),'.') AS Message;
        SELECT CONCAT('Replication is running normally for channel ', QUOTE(TRIM(BOTH from channel))) as Message;
        INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'set_channel_AP:OK',v_mysql_version);
        COMMIT;
      END IF;
    ELSE
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SELECT CONCAT('Master Auto Position has been set to ', auto_position_mode,'.') AS Message;
        INSERT into mysql.rds_history(called_by_user, action, mysql_version, auto_position) values (v_called_by_user,'set_master_AP:ERR', v_mysql_version, auto_position_mode);
        COMMIT;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered a new error. Please use SHOW SLAVE STATUS to see the error.';
      ELSE
        SELECT CONCAT('Source Auto Position has been set to ', auto_position_mode,' for channel ', QUOTE(TRIM(BOTH FROM channel)),'.') AS Message;
        INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'set_channel_AP:ERR',v_mysql_version);
        COMMIT;
        SET @message_text = CONCAT('Replication for specified channel encountered a new error.Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH from channel)));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
      END IF;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

