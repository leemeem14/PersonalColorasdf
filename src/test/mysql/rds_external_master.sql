create
    definer = rdsadmin@localhost procedure rds_external_master(IN phase varchar(10))
BEGIN
  DECLARE v_rdsrepl INT;
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_service_state ENUM('ON', 'OFF', 'BROKEN');
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_rep_status int;
  DECLARE v_rep_status_stop int;
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state() INTO sql_logging, v_called_by_user, v_mysql_version, v_service_state;
  Select count(1) into v_rep_status_stop from mysql.rds_replication_status where action = 'stop slave';
  Select count(1) into v_rep_status from mysql.rds_replication_status;
  Select count(1) into v_rdsrepl from mysql.rds_history where action = 'disable set master' and master_user = 'rdsrepladmin';
  
  IF v_called_by_user != 'rdsadmin@localhost'
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You do not have privileges to call this procedure';
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF v_rep_status = 0
    Then
      
      insert into mysql.rds_replication_status(called_by_user, action, mysql_version)values (v_called_by_user,'disable set master',v_mysql_version);
      insert into mysql.rds_history(called_by_user, action, master_user, mysql_version)values (v_called_by_user,'disable set master','rdsrepladmin',v_mysql_version);
      commit;
    ELSEIF phase not in ('enable','disable')
    then
      
      
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Please use the values enable or disable for the phase argument';
    
    
    ElseIF v_rdsrepl > 0 and phase = 'disable'
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MYSQL.RDS_SET_EXTERNAL_MASTER is disabled';
    
    ElseIF v_rdsrepl = 0 and phase = 'disable'
    THEN
      if v_service_state in ('ON'  , 'BROKEN'  )
      then
        call mysql.rds_stop_replication();
        DO SLEEP(1);
        update mysql.rds_replication_status set called_by_user=v_called_by_user, action='disable set master', mysql_version=v_mysql_version where action is not null;
        commit;
        DO SLEEP(1);
        INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_user) values (v_called_by_user,'disable set master', v_mysql_version, 'rdsrepladmin');
        commit;
        select 'Replication has been stopped and MYSQL.RDS_SET_EXTERNAL_MASTER has been disabled' as message;
      else 
        update mysql.rds_replication_status set called_by_user=v_called_by_user, action='disable set master', mysql_version=v_mysql_version where action is not null;
        commit;
        DO SLEEP(1);
        INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_user) values (v_called_by_user,'disable set master', v_mysql_version, 'rdsrepladmin');
        commit;
        Select 'MYSQL.RDS_SET_EXTERNAL_MASTER has been disabled' as message;
      end if;
    
    ELSEIF v_rdsrepl = 0 and phase = 'enable'
    THEN
      if v_service_state in ('ON'  , 'BROKEN'  )
      then
        update mysql.rds_replication_status set called_by_user=v_called_by_user,action='enable set master', mysql_version=v_mysql_version where action is not null;
        commit;
        select 'MYSQL.RDS_SET_EXTERNAL_MASTER is enabled.' as message;
        
      end if;
    ELSEIF v_rdsrepl > 0 and phase = 'enable'
    THEN
      update mysql.rds_replication_status set called_by_user=v_called_by_user,action='enable set master', mysql_version=v_mysql_version where action is not null;
      commit;
      DO SLEEP(1);
      UPDATE mysql.rds_history set action = 'enable set master' where action = 'disable set master' and master_user = 'rdsrepladmin';
      commit;
      select 'MYSQL.RDS_SET_EXTERNAL_MASTER has been enabled' as message;
    END IF;
    IF v_rep_status_stop = 1
    Then
      update mysql.rds_replication_status set called_by_user=v_called_by_user,action='stop slave', mysql_version=v_mysql_version where action is not null;
      commit;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

