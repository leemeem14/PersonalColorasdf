create table performance_schema.setup_consumers
(
    NAME    varchar(64)        not null,
    ENABLED enum ('YES', 'NO') not null
);

create unique index `PRIMARY`
    on performance_schema.setup_consumers (NAME)
    using hash;

alter table performance_schema.setup_consumers
    add primary key (NAME) using hash;

