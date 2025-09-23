create table rds_configuration
(
    action_timestamp timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    name             varchar(100)                        not null
        primary key,
    value            varchar(100)                        null,
    description      varchar(300)                        not null
);

