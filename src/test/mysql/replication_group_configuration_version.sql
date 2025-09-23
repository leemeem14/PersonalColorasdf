create table replication_group_configuration_version
(
    name    char(255) charset ascii not null comment 'The configuration name.'
        primary key,
    version bigint unsigned         not null comment 'The version of the configuration name.'
)
    comment 'The group configuration version.' row_format = DYNAMIC
                                               stats_persistent = 0;

