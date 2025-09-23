create
    definer = `mysql.sys`@localhost function sys.ps_is_consumer_enabled(in_consumer varchar(64)) returns enum ('YES', 'NO')
    comment '
Description
-----------

Determines whether a consumer is enabled (taking the consumer hierarchy into consideration)
within the Performance Schema.

An exception with errno 3047 is thrown if an unknown consumer name is passed to the function.
A consumer name of NULL returns NULL.

Parameters
-----------

in_consumer VARCHAR(64): 
  The name of the consumer to check.

Returns
-----------

ENUM(''YES'', ''NO'')

Example
-----------

mysql> SELECT sys.ps_is_consumer_enabled(''events_stages_history'');
+-----------------------------------------------------+
| sys.ps_is_consumer_enabled(''events_stages_history'') |
+-----------------------------------------------------+
| NO                                                  |
+-----------------------------------------------------+
1 row in set (0.00 sec)
'
    deterministic
    sql security invoker
    reads sql data
-- missing source code
;

