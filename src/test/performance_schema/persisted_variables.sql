create table performance_schema.persisted_variables
(
    VARIABLE_NAME  varchar(64)   not null,
    VARIABLE_VALUE varchar(1024) null
);

create unique index `PRIMARY`
    on performance_schema.persisted_variables (VARIABLE_NAME)
    using hash;

alter table performance_schema.persisted_variables
    add primary key (VARIABLE_NAME) using hash;

