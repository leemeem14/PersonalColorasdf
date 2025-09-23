create view information_schema.ADMINISTRABLE_ROLE_AUTHORIZATIONS as
select `information_schema`.`APPLICABLE_ROLES`.`USER`         AS `USER`,
       `information_schema`.`APPLICABLE_ROLES`.`HOST`         AS `HOST`,
       `information_schema`.`APPLICABLE_ROLES`.`GRANTEE`      AS `GRANTEE`,
       `information_schema`.`APPLICABLE_ROLES`.`GRANTEE_HOST` AS `GRANTEE_HOST`,
       `information_schema`.`APPLICABLE_ROLES`.`ROLE_NAME`    AS `ROLE_NAME`,
       `information_schema`.`APPLICABLE_ROLES`.`ROLE_HOST`    AS `ROLE_HOST`,
       `information_schema`.`APPLICABLE_ROLES`.`IS_GRANTABLE` AS `IS_GRANTABLE`,
       `information_schema`.`APPLICABLE_ROLES`.`IS_DEFAULT`   AS `IS_DEFAULT`,
       `information_schema`.`APPLICABLE_ROLES`.`IS_MANDATORY` AS `IS_MANDATORY`
from `information_schema`.`APPLICABLE_ROLES`
where (`information_schema`.`APPLICABLE_ROLES`.`IS_GRANTABLE` = 'YES');

