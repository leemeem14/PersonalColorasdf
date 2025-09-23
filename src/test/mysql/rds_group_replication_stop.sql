create
    definer = rdsadmin@localhost procedure rds_group_replication_stop()
BEGIN
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_plugin_installed INT UNSIGNED;
  DECLARE v_member_state VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  SELECT count(*) INTO v_plugin_installed FROM information_schema.plugins WHERE plugin_name='group_replication';
  IF v_plugin_installed = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Procedure must be executed with group_replication plugin installed.';
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    STOP GROUP_REPLICATION;
    DO SLEEP(2);
    INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'stop group replication', v_mysql_version);
    COMMIT;
    SELECT MEMBER_STATE INTO v_member_state FROM performance_schema.replication_group_members WHERE MEMBER_ID=@@server_uuid;
    IF v_member_state = 'OFFLINE' THEN
      SELECT 'Group replication stopped successfully.' AS MESSAGE;
    ELSE
      SELECT 'Group replication might have encountered an error as member state is not OFFLINE. Run select * from performance_schema.replication_group_members to get the current member state.' AS MESSAGE;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

