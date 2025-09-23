create table performance_schema.file_instances
(
    FILE_NAME  varchar(512) not null,
    EVENT_NAME varchar(128) not null,
    OPEN_COUNT int unsigned not null
);

create index EVENT_NAME
    on performance_schema.file_instances (EVENT_NAME)
    using hash;

create unique index `PRIMARY`
    on performance_schema.file_instances (FILE_NAME)
    using hash;

alter table performance_schema.file_instances
    add primary key (FILE_NAME) using hash;

