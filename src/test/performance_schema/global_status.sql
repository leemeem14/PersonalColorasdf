create table performance_schema.global_status
(
    VARIABLE_NAME  varchar(64)   not null,
    VARIABLE_VALUE varchar(1024) null
);

create unique index `PRIMARY`
    on performance_schema.global_status (VARIABLE_NAME)
    using hash;

alter table performance_schema.global_status
    add primary key (VARIABLE_NAME) using hash;

