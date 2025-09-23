create table performance_schema.user_defined_functions
(
    UDF_NAME        varchar(64)   not null,
    UDF_RETURN_TYPE varchar(20)   not null,
    UDF_TYPE        varchar(20)   not null,
    UDF_LIBRARY     varchar(1024) null,
    UDF_USAGE_COUNT bigint        null
);

create unique index `PRIMARY`
    on performance_schema.user_defined_functions (UDF_NAME)
    using hash;

alter table performance_schema.user_defined_functions
    add primary key (UDF_NAME) using hash;

