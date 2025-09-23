create
    definer = rdsadmin@localhost procedure rds_reset_external_source_for_channel(IN channel varchar(64))
BEGIN
 DECLARE v_rdsrepl INT;
 DECLARE v_mysql_version VARCHAR(20);
 DECLARE v_called_by_user VARCHAR(352);
 DECLARE v_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
 DECLARE sql_logging BOOLEAN;
 SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) into sql_logging, v_called_by_user, v_mysql_version, v_channel_service_state;
 SELECT count(1) INTO v_rdsrepl from mysql.rds_history WHERE CONVERT(action USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('disable set master' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci and CONVERT(master_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('rdsrepladmin' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
 BEGIN
   DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
   SET @@sql_log_bin=OFF;
   IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
   THEN
     INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'Starting: reset slave', v_mysql_version);
     COMMIT;
   ELSE
     INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'Starting: reset replica for channel', v_mysql_version);
     COMMIT;
   END IF;
   SET @@sql_log_bin=sql_logging;
 END;
 IF v_rdsrepl > 0 and CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
 THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: This instance is a RDS Read Replica.';
 ELSEIF CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(mysql.rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: Replication for Multi-AZ clusters is managed exclusively by RDS.';
 END IF;
 BEGIN
   DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
   SET @@sql_log_bin=OFF;
   IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
   THEN
     IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
     THEN
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t reset replication because replication isn''t configured. First run mysql.rds_set_external_master.';
     ELSE
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.';
     END IF;
   ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
   THEN
     CALL mysql.rds_clean_replication_status_for_channel(channel);
   ELSE 
     SET @cmd = CONCAT('STOP REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
     PREPARE rds_stop_replica_for_channel FROM @cmd;
     EXECUTE rds_stop_replica_for_channel;
     DEALLOCATE PREPARE rds_stop_replica_for_channel;
     DO SLEEP(2);
     CALL mysql.rds_clean_replication_status_for_channel(channel);
   END IF;
   SET @cmd = CONCAT('RESET REPLICA ALL FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
   PREPARE rds_reset_replica_for_channel FROM @cmd;
   EXECUTE rds_reset_replica_for_channel;
   DEALLOCATE PREPARE rds_reset_replica_for_channel;
   IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
   THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'reset slave', v_mysql_version);
      COMMIT;
   ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'reset replica for channel', v_mysql_version);
      COMMIT;
   END IF;
   
   IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
   THEN
     UPDATE mysql.rds_replication_status SET called_by_user=v_called_by_user, action='reset slave', mysql_version=v_mysql_version, master_host=NULL, master_port=NULL WHERE action is not null AND (CONVERT(channel_name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR channel_name IS NULL);
     COMMIT;
     SELECT 'Slave has been reset' as message;
   ELSE
     DELETE FROM mysql.rds_replication_status WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
     COMMIT;
     SELECT CONCAT('Replication has been reset for channel ', QUOTE(TRIM(BOTH FROM channel))) as message;
   END IF;
   SET @@sql_log_bin=sql_logging;
 END;
END;

