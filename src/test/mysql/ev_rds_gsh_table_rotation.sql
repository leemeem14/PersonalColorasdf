create definer = rdsadmin@localhost event ev_rds_gsh_table_rotation on schedule
    every '7' DAY
        starts '2025-07-23 23:48:25'
    on completion preserve
    disable
    do
    CALL rds_rotate_global_status_history();

