create
    definer = rdsadmin@localhost procedure rds_set_gsh_rotation(IN p_period int)
begin
  declare v_es varchar(3);
  DECLARE sql_logging BOOLEAN;
  select @@sql_log_bin into sql_logging;
  select variable_value into v_es from performance_schema.global_variables where variable_name = 'EVENT_SCHEDULER';
  
  
  
  if v_es != 'ON' then
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Scheduler is NOT Active. Please set the parameter event_scheduler=ON in your Parameter Group';
  end if;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    alter event ev_rds_gsh_table_rotation ON SCHEDULE EVERY p_period DAY STARTS CURRENT_TIMESTAMP + interval p_period day ENABLE;
    select concat('Table Rotation Enabled every ', p_period ,' Days, Scheduler is Active') as `Success`;
    SET @@sql_log_bin=sql_logging;
  END;
end;

