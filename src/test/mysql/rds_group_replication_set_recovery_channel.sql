create
    definer = rdsadmin@localhost procedure rds_group_replication_set_recovery_channel(IN passwd text)
BEGIN
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_plugin_installed INT UNSIGNED;
  DECLARE v_count_user_exist INT UNSIGNED;
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  SELECT count(*) INTO v_plugin_installed FROM information_schema.plugins WHERE plugin_name='group_replication';
  SELECT count(*) into v_count_user_exist FROM mysql.user WHERE Host='%' and user = 'rdsgrprepladmin';
  IF v_plugin_installed = 0 THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'You must install the group_replication plugin before you call the mysql.rds_group_replication_set_recovery_channel stored procedure. Install the plugin, and then run the procedure again.', MYSQL_ERRNO = 1524;
  ELSEIF v_count_user_exist = 0 THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'The database user rdsgrprepladmin must exist to set up the group replication recovery channel. Call the stored procedure mysql.rds_group_replication_create_user to create the user, and then set up the group replication recovery channel.', MYSQL_ERRNO = 3162;
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO ',
                      'SOURCE_USER=''rdsgrprepladmin''',
                      ', SOURCE_PASSWORD=', QUOTE(TRIM(BOTH FROM passwd)),
                      ' FOR CHANNEL ''group_replication_recovery'''
                      );
    PREPARE stmt FROM @cmd;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'set group replication recovery channel', v_mysql_version);
    COMMIT;
    SET @@sql_log_bin=sql_logging;
  END;
END;

