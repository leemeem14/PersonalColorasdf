create
    definer = rdsadmin@localhost procedure rds_collect_global_status_history()
begin
  declare my_row_count int(5) default 0;
  DECLARE sql_logging BOOLEAN;
  select @@sql_log_bin into sql_logging;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    
    set transaction isolation level read committed;
    insert into rds_global_status_history ( collection_start, variable_name, variable_value, variable_delta )
    select b.collection_end, a.variable_name, a.variable_value, a.variable_value-coalesce(b.variable_value,0) as variable_delta
    from performance_schema.global_status a
    left outer join rds_global_status_history b on a.variable_name = b.variable_name
    where b.collection_end = (select max(collection_end) from rds_global_status_history);
    select row_count() into my_row_count;
    if my_row_count = 0
    then
      insert into rds_global_status_history ( collection_start, variable_name, variable_value, variable_delta )
      select null, variable_name, variable_value, variable_value from performance_schema.global_status ;
    end if;
    commit;
    SET @@sql_log_bin=sql_logging;
  END;
end;

