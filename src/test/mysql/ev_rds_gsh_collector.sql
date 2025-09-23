create definer = rdsadmin@localhost event ev_rds_gsh_collector on schedule
    every '5' MINUTE
        starts '2025-07-16 23:48:25'
    on completion preserve
    disable
    do
    CALL rds_collect_global_status_history();

