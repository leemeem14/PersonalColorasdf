create view information_schema.TABLE_CONSTRAINTS_EXTENSIONS as
select `cat`.`name`                       AS `CONSTRAINT_CATALOG`,
       `sch`.`name`                       AS `CONSTRAINT_SCHEMA`,
       `idx`.`name`                       AS `CONSTRAINT_NAME`,
       `tbl`.`name`                       AS `TABLE_NAME`,
       `idx`.`engine_attribute`           AS `ENGINE_ATTRIBUTE`,
       `idx`.`secondary_engine_attribute` AS `SECONDARY_ENGINE_ATTRIBUTE`
from (((`indexes` `idx` join `tables` `tbl` on ((`idx`.`table_id` = `tbl`.`id`))) join `schemata` `sch`
       on ((`tbl`.`schema_id` = `sch`.`id`))) join `catalogs` `cat` on ((`cat`.`id` = `sch`.`catalog_id`)))
where ((0 <> can_access_table(`sch`.`name`, `tbl`.`name`)) and
       (0 <> is_visible_dd_object(`tbl`.`hidden`, false, `idx`.`options`)));

