create
    definer = rdsadmin@localhost function rds_replication_service_state_for_channel(channel varchar(64)) returns enum ('ON', 'OFF', 'BROKEN', 'NOT_EXIST')
    reads sql data
BEGIN
  DECLARE v_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  SELECT COALESCE(MAX(
    CASE WHEN rcs.service_state = 'ON' AND rca.service_state = 'ON' THEN 'ON'
       WHEN rcs.service_state = 'OFF' AND rca.service_state = 'OFF' THEN 'OFF'
       ELSE 'BROKEN' END), 'NOT_EXIST')
  INTO v_service_state
  FROM performance_schema.replication_connection_status rcs
           JOIN performance_schema.replication_applier_status rca USING (channel_name)
  WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  RETURN v_service_state;
END;

