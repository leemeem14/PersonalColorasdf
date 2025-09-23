create
    definer = `mysql.sys`@localhost function sys.ps_is_instrument_default_enabled(in_instrument varchar(128)) returns enum ('YES', 'NO')
    comment '
Description
-----------

Returns whether an instrument is enabled by default in this version of MySQL.

Parameters
-----------

in_instrument VARCHAR(128): 
  The instrument to check.

Returns
-----------

ENUM(''YES'', ''NO'')

Example
-----------

mysql> SELECT sys.ps_is_instrument_default_enabled(''statement/sql/select'');
+--------------------------------------------------------------+
| sys.ps_is_instrument_default_enabled(''statement/sql/select'') |
+--------------------------------------------------------------+
| YES                                                          |
+--------------------------------------------------------------+
1 row in set (0.00 sec)
'
    deterministic
    sql security invoker
    reads sql data
-- missing source code
;

