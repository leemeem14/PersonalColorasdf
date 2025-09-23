create table performance_schema.setup_instruments
(
    NAME          varchar(128)                                                                                   not null,
    ENABLED       enum ('YES', 'NO')                                                                             not null,
    TIMED         enum ('YES', 'NO')                                                                             null,
    PROPERTIES    set ('singleton', 'progress', 'user', 'global_statistics', 'mutable', 'controlled_by_default') not null,
    FLAGS         set ('controlled')                                                                             null,
    VOLATILITY    int                                                                                            not null,
    DOCUMENTATION longtext                                                                                       null
);

create unique index `PRIMARY`
    on performance_schema.setup_instruments (NAME)
    using hash;

alter table performance_schema.setup_instruments
    add primary key (NAME) using hash;

