create
    definer = rdsadmin@localhost function rds_replication_service_state() returns enum ('ON', 'OFF', 'BROKEN')
    reads sql data
BEGIN
  DECLARE v_service_state ENUM('ON', 'OFF', 'BROKEN');
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
    
    SELECT COALESCE(MAX(
      CASE WHEN rcs.service_state = 'ON' and rca.service_state = 'ON' THEN 'ON'
           WHEN rcs.service_state = 'OFF' and rca.service_state = 'OFF' THEN 'OFF'
           ELSE 'BROKEN' END), 'OFF')
    INTO v_service_state
    FROM performance_schema.replication_connection_status rcs
    JOIN performance_schema.replication_applier_status rca USING (channel_name)
    WHERE channel_name='';
  RETURN v_service_state;
END;

