create table performance_schema.setup_threads
(
    NAME          varchar(128)              not null,
    ENABLED       enum ('YES', 'NO')        not null,
    HISTORY       enum ('YES', 'NO')        not null,
    PROPERTIES    set ('singleton', 'user') not null,
    VOLATILITY    int                       not null,
    DOCUMENTATION longtext                  null
);

create unique index `PRIMARY`
    on performance_schema.setup_threads (NAME)
    using hash;

alter table performance_schema.setup_threads
    add primary key (NAME) using hash;

