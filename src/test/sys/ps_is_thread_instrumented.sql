create
    definer = `mysql.sys`@localhost function sys.ps_is_thread_instrumented(in_connection_id bigint unsigned) returns enum ('YES', 'NO', 'UNKNOWN')
    comment '
Description
-----------

Checks whether the provided connection id is instrumented within Performance Schema.

Parameters
-----------

in_connection_id (BIGINT UNSIGNED):
  The id of the connection to check.

Returns
-----------

ENUM(''YES'', ''NO'', ''UNKNOWN'')

Example
-----------

mysql> SELECT sys.ps_is_thread_instrumented(CONNECTION_ID());
+------------------------------------------------+
| sys.ps_is_thread_instrumented(CONNECTION_ID()) |
+------------------------------------------------+
| YES                                            |
+------------------------------------------------+
'
    sql security invoker
    reads sql data
-- missing source code
;

