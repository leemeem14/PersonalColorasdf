create table component
(
    component_id       int unsigned auto_increment
        primary key,
    component_group_id int unsigned not null,
    component_urn      text         not null
)
    comment 'Components' charset = utf8mb3
                         row_format = DYNAMIC;

