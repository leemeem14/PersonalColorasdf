create
    definer = rdsadmin@localhost procedure rds_set_external_source_with_auto_position_for_channel(IN host varchar(255),
                                                                                                  IN port int,
                                                                                                  IN user text,
                                                                                                  IN passwd text,
                                                                                                  IN enable_ssl_encryption tinyint(1),
                                                                                                  IN delay int,
                                                                                                  IN channel varchar(64))
BEGIN
  DECLARE v_rdsrepl INT;
  DECLARE v_same_name_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE sql_logging BOOLEAN;
  DECLARE v_channel_count INT;
  DECLARE v_same_source_count INT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_same_name_channel_service_state;
  SELECT count(1) INTO v_rdsrepl from mysql.rds_history WHERE CONVERT(action USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('disable set master' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci and CONVERT(master_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('rdsrepladmin' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  SELECT count(1) INTO v_channel_count FROM performance_schema.replication_connection_status WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  SELECT count(1) INTO v_same_source_count FROM performance_schema.replication_connection_configuration rcc WHERE rcc.HOST = host AND rcc.PORT = port AND CONVERT(QUOTE(rcc.CHANNEL_NAME) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_ssl, master_delay, auto_position)
      VALUES (v_called_by_user,'Starting: set master AP', v_mysql_version, trim(both from host), port, trim(both from user), enable_ssl_encryption, delay, 1);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_ssl, master_delay, auto_position)
      VALUES (v_called_by_user,'Starting: set channel AP', v_mysql_version, trim(both from host), port, trim(both from user), enable_ssl_encryption, delay, 1);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF delay NOT BETWEEN 0 AND 86400
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'For source delay the value must be between 0 and 86400 inclusive.';
  END IF;
  IF v_rdsrepl > 0 and CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: This instance is a RDS Read Replica.';
  ELSEIF CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(mysql.rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: Replication for Multi-AZ clusters is managed exclusively by RDS.';
  END IF;
  IF CONVERT(v_same_name_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR CONVERT(v_same_name_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('BROKEN' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t modify replication because replication is running. First call mysql.rds_stop_replication.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t modify the given channel because replication is running. First call mysql.rds_stop_replication_for_channel.';
    END IF;
  END IF;
  
  IF v_channel_count >= 15
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maximum 15 channels are allowed in multi source replication on RDS.';
  END IF;
  
  IF v_same_source_count > 0
  THEN
    
    SET @error_message = CONCAT('Use multiple channels to replicate from the host: ', host, ' and port: ', port, ' is not supported.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    
    SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO',
                      ' SOURCE_HOST = ', QUOTE(TRIM(BOTH FROM host)),
                      ', SOURCE_PORT = ', port, 
                      ', SOURCE_USER = ', QUOTE(TRIM(BOTH FROM user)),
                      ', SOURCE_PASSWORD = ', QUOTE(TRIM(BOTH FROM passwd)),
                      ', SOURCE_SSL = ', enable_ssl_encryption, 
                      ', SOURCE_AUTO_POSITION = 1',
                      ', SOURCE_DELAY = ', delay, 
                      ' FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel))
                     );
    PREPARE rds_set_source_for_channel FROM @cmd;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      UPDATE mysql.rds_replication_status SET called_by_user=v_called_by_user, action='set master', mysql_version=v_mysql_version , master_host=trim(both from host), master_port=port WHERE action is not null AND (CONVERT(channel_name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR channel_name IS NULL);
      COMMIT;
    ELSE
      DELETE FROM mysql.rds_replication_status WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
      INSERT INTO mysql.rds_replication_status(called_by_user, action, mysql_version, master_host, master_port, channel_name)
        VALUES (v_called_by_user, 'set channel source', v_mysql_version, trim(both from host), port, channel);
      COMMIT;
    END IF;
    CALL mysql.rds_clean_replication_status_for_channel(channel);
    EXECUTE rds_set_source_for_channel;
    DEALLOCATE PREPARE rds_set_source_for_channel;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_ssl, master_delay, auto_position)
        VALUES (v_called_by_user,'set master with AP', v_mysql_version, trim(both from host), port, trim(both from user), enable_ssl_encryption, delay, 1);
      COMMIT;
      
      
      UPDATE mysql.rds_configuration
        SET mysql.rds_configuration.value = delay
        WHERE CAST(mysql.rds_configuration.name AS BINARY) = 'source delay';
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_ssl, master_delay, auto_position)
        VALUES (v_called_by_user,'set channel with AP', v_mysql_version, trim(both from host), port, trim(both from user), enable_ssl_encryption, delay, 1);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

