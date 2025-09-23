create table rds_replication_status
(
    action_timestamp       timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    called_by_user         varchar(352)                          not null,
    action                 varchar(20)                           not null,
    mysql_version          varchar(50)                           not null,
    master_host            varchar(255)                          null,
    master_port            int                                   null,
    replication_log_file   text                                  null,
    replication_stop_point bigint                                null,
    replication_gtid       text                                  null,
    channel_name           varchar(64) default ''                null
);

