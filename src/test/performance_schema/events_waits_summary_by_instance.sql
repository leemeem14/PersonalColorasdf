create table performance_schema.events_waits_summary_by_instance
(
    EVENT_NAME            varchar(128)    not null,
    OBJECT_INSTANCE_BEGIN bigint unsigned not null,
    COUNT_STAR            bigint unsigned not null,
    SUM_TIMER_WAIT        bigint unsigned not null,
    MIN_TIMER_WAIT        bigint unsigned not null,
    AVG_TIMER_WAIT        bigint unsigned not null,
    MAX_TIMER_WAIT        bigint unsigned not null
);

create index EVENT_NAME
    on performance_schema.events_waits_summary_by_instance (EVENT_NAME)
    using hash;

create unique index `PRIMARY`
    on performance_schema.events_waits_summary_by_instance (OBJECT_INSTANCE_BEGIN)
    using hash;

alter table performance_schema.events_waits_summary_by_instance
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

