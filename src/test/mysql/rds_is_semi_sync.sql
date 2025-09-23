create
    definer = rdsadmin@localhost function rds_is_semi_sync() returns enum ('SOURCE', 'REPLICA', 'NO') reads sql data
BEGIN
  DECLARE is_semi_sync_source INTEGER;
  DECLARE is_semi_sync_replica INTEGER;
  
  
  
  
  
  
  
  
  
  
  SELECT SUM(variable_value = 'ON' AND variable_name in ('rpl_semi_sync_source_enabled', 'rpl_semi_sync_master_enabled')),
         SUM(variable_value = 'ON' AND variable_name in ('rpl_semi_sync_replica_enabled', 'rpl_semi_sync_slave_enabled'))
  INTO is_semi_sync_source, is_semi_sync_replica
  FROM performance_schema.global_variables;
  IF is_semi_sync_source > 0 THEN
    RETURN 'SOURCE';
  ELSEIF is_semi_sync_replica > 0 THEN
    RETURN 'REPLICA';
  ELSE
    RETURN 'NO';
  END IF;
END;

