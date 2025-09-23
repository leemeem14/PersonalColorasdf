create table rds_upgrade_prechecks
(
    id                    int auto_increment
        primary key,
    action                varchar(20)                            not null,
    status                text                                   not null,
    engine_version        text                                   null,
    target_engine_name    text                                   null,
    target_engine_version text                                   null,
    start_timestamp       timestamp    default CURRENT_TIMESTAMP not null,
    last_timestamp        timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    prechecks_completed   int unsigned default '0'               not null,
    prechecks_remaining   int unsigned default '0'               not null,
    skip_prechecks        tinyint(1)                             null,
    summary               text                                   null
);

