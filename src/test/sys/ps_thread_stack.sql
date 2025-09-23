create
    definer = `mysql.sys`@localhost function sys.ps_thread_stack(thd_id bigint unsigned, debug tinyint(1)) returns longtext
    comment '
Description
-----------

Outputs a JSON formatted stack of all statements, stages and events
within Performance Schema for the specified thread.

Parameters
-----------

thd_id (BIGINT UNSIGNED):
  The id of the thread to trace. This should match the thread_id
  column from the performance_schema.threads table.
in_verbose (BOOLEAN):
  Include file:lineno information in the events.

Example
-----------

(line separation added for output)

mysql> SELECT sys.ps_thread_stack(37, FALSE) AS thread_stack\G
*************************** 1. row ***************************
thread_stack: {"rankdir": "LR","nodesep": "0.10","stack_created": "2014-02-19 13:39:03",
"mysql_version": "5.7.3-m13","mysql_user": "root@localhost","events": 
[{"nesting_event_id": "0", "event_id": "10", "timer_wait": 256.35, "event_info": 
"sql/select", "wait_info": "select @@version_comment limit 1\nerrors: 0\nwarnings: 0\nlock time:
...
'
    sql security invoker
    reads sql data
-- missing source code
;

