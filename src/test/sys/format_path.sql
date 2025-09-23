create
    definer = `mysql.sys`@localhost function sys.format_path(in_path varchar(512)) returns varchar(512) comment '
Description
-----------

Takes a raw path value, and strips out the datadir or tmpdir
replacing with @@datadir and @@tmpdir respectively.

Also normalizes the paths across operating systems, so backslashes
on Windows are converted to forward slashes

Parameters
-----------

path (VARCHAR(512)):
  The raw file path value to format.

Returns
-----------

VARCHAR(512) CHARSET UTF8MB4

Example
-----------

mysql> select @@datadir;
+-----------------------------------------------+
| @@datadir                                     |
+-----------------------------------------------+
| /Users/mark/sandboxes/SmallTree/AMaster/data/ |
+-----------------------------------------------+
1 row in set (0.06 sec)

mysql> select format_path(''/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD'') AS path;
+--------------------------+
| path                     |
+--------------------------+
| @@datadir/mysql/proc.MYD |
+--------------------------+
1 row in set (0.03 sec)
' deterministic sql security invoker no sql
-- missing source code
;

