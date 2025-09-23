create table performance_schema.rwlock_instances
(
    NAME                      varchar(128)    not null,
    OBJECT_INSTANCE_BEGIN     bigint unsigned not null,
    WRITE_LOCKED_BY_THREAD_ID bigint unsigned null,
    READ_LOCKED_BY_COUNT      int unsigned    not null
);

create index NAME
    on performance_schema.rwlock_instances (NAME)
    using hash;

create unique index `PRIMARY`
    on performance_schema.rwlock_instances (OBJECT_INSTANCE_BEGIN)
    using hash;

create index WRITE_LOCKED_BY_THREAD_ID
    on performance_schema.rwlock_instances (WRITE_LOCKED_BY_THREAD_ID)
    using hash;

alter table performance_schema.rwlock_instances
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

