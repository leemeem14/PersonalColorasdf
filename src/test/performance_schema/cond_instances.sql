create table performance_schema.cond_instances
(
    NAME                  varchar(128)    not null,
    OBJECT_INSTANCE_BEGIN bigint unsigned not null
);

create index NAME
    on performance_schema.cond_instances (NAME)
    using hash;

create unique index `PRIMARY`
    on performance_schema.cond_instances (OBJECT_INSTANCE_BEGIN)
    using hash;

alter table performance_schema.cond_instances
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

