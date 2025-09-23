create
    definer = rdsadmin@localhost procedure rds_show_upgrade_prechecks_summary()
BEGIN
SELECT summary from mysql.rds_upgrade_prechecks ORDER BY id DESC LIMIT 1;
END;

