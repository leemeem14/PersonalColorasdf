create view information_schema.VIEW_TABLE_USAGE as
select `cat`.`name`          AS `VIEW_CATALOG`,
       `sch`.`name`          AS `VIEW_SCHEMA`,
       `vw`.`name`           AS `VIEW_NAME`,
       `vtu`.`table_catalog` AS `TABLE_CATALOG`,
       `vtu`.`table_schema`  AS `TABLE_SCHEMA`,
       `vtu`.`table_name`    AS `TABLE_NAME`
from (((`tables` `vw` join `schemata` `sch` on ((`vw`.`schema_id` = `sch`.`id`))) join `catalogs` `cat`
       on ((`cat`.`id` = `sch`.`catalog_id`))) join `view_table_usage` `vtu` on ((`vtu`.`view_id` = `vw`.`id`)))
where ((0 <> can_access_table(`vtu`.`table_schema`, `vtu`.`table_name`)) and (`vw`.`type` = 'VIEW') and
       (0 <> can_access_view(`sch`.`name`, `vw`.`name`, `vw`.`view_definer`, `vw`.`options`)));

