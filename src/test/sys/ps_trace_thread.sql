create
    definer = `mysql.sys`@localhost procedure sys.ps_trace_thread(IN in_thread_id bigint unsigned,
                                                                  IN in_outfile varchar(255),
                                                                  IN in_max_runtime decimal(20, 2),
                                                                  IN in_interval decimal(20, 2),
                                                                  IN in_start_fresh tinyint(1),
                                                                  IN in_auto_setup tinyint(1), IN in_debug tinyint(1))
    comment '
Description
-----------

Dumps all data within Performance Schema for an instrumented thread,
to create a DOT formatted graph file. 

Each resultset returned from the procedure should be used for a complete graph

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_thread_id (BIGINT UNSIGNED):
  The thread that you would like a stack trace for
in_outfile  (VARCHAR(255)):
  The filename the dot file will be written to
in_max_runtime (DECIMAL(20,2)):
  The maximum time to keep collecting data.
  Use NULL to get the default which is 60 seconds.
in_interval (DECIMAL(20,2)): 
  How long to sleep between data collections. 
  Use NULL to get the default which is 1 second.
in_start_fresh (BOOLEAN):
  Whether to reset all Performance Schema data before tracing.
in_auto_setup (BOOLEAN):
  Whether to disable all other threads and enable all consumers/instruments. 
  This will also reset the settings at the end of the run.
in_debug (BOOLEAN):
  Whether you would like to include file:lineno in the graph

Example
-----------

mysql> CALL sys.ps_trace_thread(25, CONCAT(''/tmp/stack-'', REPLACE(NOW(), '' '', ''-''), ''.dot''), NULL, NULL, TRUE, TRUE, TRUE);
+-------------------+
| summary           |
+-------------------+
| Disabled 1 thread |
+-------------------+
1 row in set (0.00 sec)

+---------------------------------------------+
| Info                                        |
+---------------------------------------------+
| Data collection starting for THREAD_ID = 25 |
+---------------------------------------------+
1 row in set (0.03 sec)

+-----------------------------------------------------------+
| Info                                                      |
+-----------------------------------------------------------+
| Stack trace written to /tmp/stack-2014-02-16-21:18:41.dot |
+-----------------------------------------------------------+
1 row in set (60.07 sec)

+-------------------------------------------------------------------+
| Convert to PDF                                                    |
+-------------------------------------------------------------------+
| dot -Tpdf -o /tmp/stack_25.pdf /tmp/stack-2014-02-16-21:18:41.dot |
+-------------------------------------------------------------------+
1 row in set (60.07 sec)

+-------------------------------------------------------------------+
| Convert to PNG                                                    |
+-------------------------------------------------------------------+
| dot -Tpng -o /tmp/stack_25.png /tmp/stack-2014-02-16-21:18:41.dot |
+-------------------------------------------------------------------+
1 row in set (60.07 sec)

+------------------+
| summary          |
+------------------+
| Enabled 1 thread |
+------------------+
1 row in set (60.32 sec)
'
    sql security invoker
    modifies sql data
-- missing source code
;

