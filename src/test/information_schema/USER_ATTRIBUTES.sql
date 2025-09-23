create view information_schema.USER_ATTRIBUTES as
select `user`.`User`                                                      AS `USER`,
       `user`.`Host`                                                      AS `HOST`,
       json_unquote(json_extract(`user`.`User_attributes`, '$.metadata')) AS `ATTRIBUTE`
from `user`
where (0 <> can_access_user(`user`.`User`, `user`.`Host`));

