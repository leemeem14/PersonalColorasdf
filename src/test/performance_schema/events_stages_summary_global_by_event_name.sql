create table performance_schema.events_stages_summary_global_by_event_name
(
    EVENT_NAME     varchar(128)    not null,
    COUNT_STAR     bigint unsigned not null,
    SUM_TIMER_WAIT bigint unsigned not null,
    MIN_TIMER_WAIT bigint unsigned not null,
    AVG_TIMER_WAIT bigint unsigned not null,
    MAX_TIMER_WAIT bigint unsigned not null
);

create unique index `PRIMARY`
    on performance_schema.events_stages_summary_global_by_event_name (EVENT_NAME)
    using hash;

alter table performance_schema.events_stages_summary_global_by_event_name
    add primary key (EVENT_NAME) using hash;

