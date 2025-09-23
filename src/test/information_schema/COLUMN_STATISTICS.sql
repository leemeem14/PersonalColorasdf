create view information_schema.COLUMN_STATISTICS as
select `column_statistics`.`schema_name` AS `SCHEMA_NAME`,
       `column_statistics`.`table_name`  AS `TABLE_NAME`,
       `column_statistics`.`column_name` AS `COLUMN_NAME`,
       `column_statistics`.`histogram`   AS `HISTOGRAM`
from `column_statistics`
where (0 <> can_access_table(`column_statistics`.`schema_name`, `column_statistics`.`table_name`));

