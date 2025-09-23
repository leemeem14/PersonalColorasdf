create view information_schema.COLLATION_CHARACTER_SET_APPLICABILITY as
select `col`.`name` AS `COLLATION_NAME`, `cs`.`name` AS `CHARACTER_SET_NAME`
from (`character_sets` `cs` join `collations` `col` on ((`cs`.`id` = `col`.`character_set_id`)));

