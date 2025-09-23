create
    definer = `mysql.sys`@localhost procedure sys.create_synonym_db(IN in_db_name varchar(64), IN in_synonym varchar(64))
    comment '
Description
-----------

Takes a source database name and synonym name, and then creates the 
synonym database with views that point to all of the tables within
the source database.

Useful for creating a "ps" synonym for "performance_schema",
or "is" instead of "information_schema", for example.

Parameters
-----------

in_db_name (VARCHAR(64)):
  The database name that you would like to create a synonym for.
in_synonym (VARCHAR(64)):
  The database synonym name.

Example
-----------

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test               |
+--------------------+
5 rows in set (0.00 sec)

mysql> CALL sys.create_synonym_db(''performance_schema'', ''ps'');
+---------------------------------------+
| summary                               |
+---------------------------------------+
| Created 74 views in the `ps` database |
+---------------------------------------+
1 row in set (8.57 sec)

Query OK, 0 rows affected (8.57 sec)

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| ps                 |
| sys                |
| test               |
+--------------------+
6 rows in set (0.00 sec)

mysql> SHOW FULL TABLES FROM ps;
+------------------------------------------------------+------------+
| Tables_in_ps                                         | Table_type |
+------------------------------------------------------+------------+
| accounts                                             | VIEW       |
| cond_instances                                       | VIEW       |
| events_stages_current                                | VIEW       |
| events_stages_history                                | VIEW       |
...
'
    sql security invoker
    modifies sql data
-- missing source code
;

