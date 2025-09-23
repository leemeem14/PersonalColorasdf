create
    definer = rdsadmin@localhost procedure rds_group_replication_advance_gtid(IN begin_id int unsigned, IN end_id int unsigned, IN server_uuid text)
BEGIN
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_plugin_installed INT UNSIGNED;
  DECLARE v_loop_id INT UNSIGNED;
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  SELECT count(*) INTO v_plugin_installed FROM information_schema.plugins WHERE plugin_name='group_replication';
  IF v_plugin_installed = 0 THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Procedure must be executed with group_replication plugin installed.', MYSQL_ERRNO = 1524;
  END IF;
  IF begin_id = 0 or end_id = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both start and end transaction ID of the transactions should be bigger than 0.', MYSQL_ERRNO = 1644;
  ELSEIF begin_id > end_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Start transaction ID should be smaller or equal to the end transaction ID.', MYSQL_ERRNO = 1644;
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; SET @@GTID_NEXT='AUTOMATIC'; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET v_loop_id = begin_id;
    loop_label: LOOP
      IF v_loop_id > end_id THEN
        LEAVE loop_label;
      END IF;
      SET @@GTID_NEXT=CONCAT(server_uuid, ':', v_loop_id);
      COMMIT;
      SET v_loop_id = v_loop_id + 1;
      SET @@GTID_NEXT='AUTOMATIC';
    END LOOP;
    
    INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_gtid) values
                                 (v_called_by_user, 'advance gtid', v_mysql_version, CONCAT(server_uuid, ':', begin_id, '-', end_id));
    COMMIT;
    SET @@sql_log_bin=sql_logging;
  END;
END;

