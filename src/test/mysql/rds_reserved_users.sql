create definer = rdsadmin@localhost view rds_reserved_users as
(select `mysql`.`user`.`User` AS `user`, 'localhost' AS `host`, 'RDS management user' AS `description`
 from `mysql`.`user`
 where ((convert(`mysql`.`user`.`User` using utf8mb4) collate utf8mb4_0900_ai_ci) =
        (convert('rdsadmin' using utf8mb4) collate utf8mb4_0900_ai_ci))
 limit 1)
union all
(select `mysql`.`user`.`User` AS `user`, '%' AS `host`, 'RDS replication user' AS `description`
 from `mysql`.`user`
 where ((convert(`mysql`.`user`.`User` using utf8mb4) collate utf8mb4_0900_ai_ci) =
        (convert('rdsrepladmin' using utf8mb4) collate utf8mb4_0900_ai_ci))
 limit 1)
union all
select 'mysql.session'                                                                                  AS `user`,
       'localhost'                                                                                      AS `host`,
       'MySQL reserved system account (https://dev.mysql.com/doc/refman/8.0/en/reserved-accounts.html)' AS `description`
union all
select 'mysql.sys'                                                                                      AS `user`,
       'localhost'                                                                                      AS `host`,
       'MySQL reserved system account (https://dev.mysql.com/doc/refman/8.0/en/reserved-accounts.html)' AS `description`
union all
select 'mysql.infoschema'                                                                               AS `user`,
       'localhost'                                                                                      AS `host`,
       'MySQL reserved system account (https://dev.mysql.com/doc/refman/8.0/en/reserved-accounts.html)' AS `description`
union all
select `mysql`.`user`.`User` AS `user`, '%' AS `host`, 'RDS multi-AZ topology manager' AS `description`
from `mysql`.`user`
where (((convert(`mysql`.`user`.`User` using utf8mb4) collate utf8mb4_0900_ai_ci) =
        (convert('rdstopmgr' using utf8mb4) collate utf8mb4_0900_ai_ci)) and
       ((convert(`rds_is_semi_sync`() using utf8mb4) collate utf8mb4_0900_ai_ci) <>
        (convert('NO' using utf8mb4) collate utf8mb4_0900_ai_ci)));

