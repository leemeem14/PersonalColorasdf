create table performance_schema.variables_by_thread
(
    THREAD_ID      bigint unsigned not null,
    VARIABLE_NAME  varchar(64)     not null,
    VARIABLE_VALUE varchar(1024)   null
);

create unique index `PRIMARY`
    on performance_schema.variables_by_thread (THREAD_ID, VARIABLE_NAME)
    using hash;

alter table performance_schema.variables_by_thread
    add primary key (THREAD_ID, VARIABLE_NAME) using hash;

