create table rds_history
(
    action_timestamp timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    called_by_user   varchar(352)                        not null,
    action           varchar(40)                         null,
    mysql_version    varchar(50)                         not null,
    master_host      varchar(255)                        null,
    master_port      int                                 null,
    master_user      varchar(96)                         null,
    master_log_file  varchar(50)                         null,
    master_log_pos   mediumtext                          null,
    master_ssl       tinyint(1)                          null,
    master_delay     int                                 null,
    auto_position    tinyint(1)                          null,
    master_gtid      text                                null
);

