create
    definer = rdsadmin@localhost procedure rds_group_replication_create_user(IN passwd text)
BEGIN
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_plugin_installed INT UNSIGNED;
  DECLARE v_count_user_exist INT UNSIGNED;
  DECLARE v_count_mysql_session_exist INT UNSIGNED;
  DECLARE sql_logging BOOLEAN;
  DECLARE user_altered INT DEFAULT 0;
  SELECT @@sql_log_bin, user(), version() INTO sql_logging, v_called_by_user, v_mysql_version;
  SELECT count(*) INTO v_plugin_installed FROM information_schema.plugins WHERE plugin_name='group_replication';
  IF v_plugin_installed = 0 THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'You must install the group_replication plugin before you call the mysql.rds_group_replication_create_user stored procedure. Install the plugin, and then run the procedure again.', MYSQL_ERRNO = 1524;
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    
    SET @@sql_log_bin=OFF;
    
    SELECT count(*) INTO v_count_mysql_session_exist FROM mysql.user WHERE Host='localhost' AND user = 'mysql.session';
    
    IF v_count_mysql_session_exist=0 THEN
      CREATE USER IF NOT EXISTS 'mysql.session'@'localhost'
      IDENTIFIED WITH 'caching_sha2_password' AS '$A$005$THISISACOMBINATIONOFINVALIDSALTANDPASSWORDTHATMUSTNEVERBRBEUSED'
      REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT LOCK PASSWORD HISTORY DEFAULT PASSWORD REUSE INTERVAL DEFAULT PASSWORD REQUIRE CURRENT DEFAULT;
      GRANT SELECT ON mysql.user to 'mysql.session'@localhost;
      GRANT SELECT ON performance_schema.* TO 'mysql.session'@localhost;
    END IF;
    
    SELECT count(*) into v_count_user_exist FROM mysql.user WHERE Host='%' and user = 'rdsgrprepladmin';
    IF v_count_user_exist>0 THEN
      SET @alter_u_cmd = CONCAT('ALTER USER rdsgrprepladmin@''%'' IDENTIFIED BY ',
                  QUOTE(TRIM(BOTH FROM passwd)),
                  ';'
                  );
      PREPARE alter_u_cmd FROM @alter_u_cmd;
      EXECUTE alter_u_cmd;
      SET user_altered=1;
    ELSE
      SET @create_u_cmd = CONCAT('CREATE USER rdsgrprepladmin@''%'' IDENTIFIED BY ',
                    QUOTE(TRIM(BOTH FROM passwd)),
                    ';'
                    );
      PREPARE create_u_stmt FROM @create_u_cmd;
      EXECUTE create_u_stmt;
    END IF;
    SET @grant_u_cmd = CONCAT('GRANT REPLICATION SLAVE, GROUP_REPLICATION_STREAM ',
                  'ON *.* TO rdsgrprepladmin@''%'';');
    PREPARE grant_u_stmt FROM @grant_u_cmd;
    EXECUTE grant_u_stmt;
    FLUSH PRIVILEGES;
    
    IF user_altered=1 THEN
          SELECT 'Warning: Group replication user already exists, password altered. Please ensure that all your instances have the same password for this user.' AS Message;
          INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'group replication user altered.', v_mysql_version);
    ELSE
          SELECT 'Group replication user created successfully.' AS Message;
          INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user, 'group replication user created.', v_mysql_version);
    END IF;
    
    SET @@sql_log_bin=sql_logging;
  END;
END;

