create table performance_schema.setup_actors
(
    HOST    char(255)          default '%'   not null,
    USER    char(32)           default '%'   not null,
    ROLE    char(32)           default '%'   not null,
    ENABLED enum ('YES', 'NO') default 'YES' not null,
    HISTORY enum ('YES', 'NO') default 'YES' not null
);

create unique index `PRIMARY`
    on performance_schema.setup_actors (HOST, USER, ROLE)
    using hash;

alter table performance_schema.setup_actors
    add primary key (HOST, USER, ROLE) using hash;

