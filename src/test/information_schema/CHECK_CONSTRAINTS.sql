create view information_schema.CHECK_CONSTRAINTS as
select `cat`.`name`             AS `CONSTRAINT_CATALOG`,
       `sch`.`name`             AS `CONSTRAINT_SCHEMA`,
       `cc`.`name`              AS `CONSTRAINT_NAME`,
       `cc`.`check_clause_utf8` AS `CHECK_CLAUSE`
from (((`check_constraints` `cc` join `tables` `tbl` on ((`cc`.`table_id` = `tbl`.`id`))) join `schemata` `sch`
       on ((`tbl`.`schema_id` = `sch`.`id`))) join `catalogs` `cat` on ((`cat`.`id` = `sch`.`catalog_id`)))
where ((0 <> can_access_table(`sch`.`name`, `tbl`.`name`)) and (0 <> is_visible_dd_object(`tbl`.`hidden`)));

