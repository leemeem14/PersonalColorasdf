create table performance_schema.processlist
(
    ID               bigint unsigned               not null,
    USER             varchar(32)                   null,
    HOST             varchar(261)                  null,
    DB               varchar(64)                   null,
    COMMAND          varchar(16)                   null,
    TIME             bigint                        null,
    STATE            varchar(64)                   null,
    INFO             longtext                      null,
    EXECUTION_ENGINE enum ('PRIMARY', 'SECONDARY') null
);

create unique index `PRIMARY`
    on performance_schema.processlist (ID)
    using hash;

alter table performance_schema.processlist
    add primary key (ID) using hash;

