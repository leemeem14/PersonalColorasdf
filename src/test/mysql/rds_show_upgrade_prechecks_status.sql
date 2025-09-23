create
    definer = rdsadmin@localhost procedure rds_show_upgrade_prechecks_status()
BEGIN
SELECT action, status, engine_version, target_engine_name, target_engine_version, start_timestamp, last_timestamp, prechecks_completed, prechecks_remaining
FROM mysql.rds_upgrade_prechecks WHERE CONVERT(action USING utf8mb4) COLLATE utf8mb4_0900_ai_ci IN (CONVERT('start_precheck' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci, CONVERT('engine upgrade' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci) ORDER BY id DESC LIMIT 1;
END;

