create table performance_schema.mutex_instances
(
    NAME                  varchar(128)    not null,
    OBJECT_INSTANCE_BEGIN bigint unsigned not null,
    LOCKED_BY_THREAD_ID   bigint unsigned null
);

create index LOCKED_BY_THREAD_ID
    on performance_schema.mutex_instances (LOCKED_BY_THREAD_ID)
    using hash;

create index NAME
    on performance_schema.mutex_instances (NAME)
    using hash;

create unique index `PRIMARY`
    on performance_schema.mutex_instances (OBJECT_INSTANCE_BEGIN)
    using hash;

alter table performance_schema.mutex_instances
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

