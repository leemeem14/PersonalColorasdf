create table rds_global_status_history
(
    collection_end   timestamp default CURRENT_TIMESTAMP not null,
    collection_start timestamp                           null,
    variable_name    varchar(64)                         not null,
    variable_value   varchar(1024)                       not null,
    variable_delta   int                                 not null,
    primary key (collection_end, variable_name)
)
    charset = latin1;

