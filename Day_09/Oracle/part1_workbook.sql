
create or replace synonym input_data for day09_part1;
select * from day09_part1;


select sum(the_sum) from (
select history_id, sum(value) the_sum
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff
group by history_id
)
;
--2101134781, too low

select * from seq_line_1;
select * from pyramid;

create or replace view pyramid as 
with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from sequences
  
  union all
  
  select history_id, seq_num
    , value - lag(value,1) over (partition by history_id order by seq_num)
    , diff_level +1
  from a
  where diff_level < 1000
)
select * from a
where value is not null
/
select * from pyramid where history_id = 1;

select history_id, sum(value) the_sum
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff
group by history_id;








exec drop_object_if_exists('sequences','view');
exec drop_object_if_exists('sequences','materialized view');

create materialized view sequences as 
select
  to_number(i.lineno) history_id
  , n.id seq_num
  , to_number(n.column_value) value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
select * from sequences;

exec drop_object_if_exists('pyramid','view');
exec drop_object_if_exists('pyramid','materialized view');

create materialized view pyramid as 
with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from sequences
  
  union all
  
  select history_id, seq_num
    , value - lag(value,1) over (partition by history_id order by seq_num)
    , diff_level +1
  from a
  where diff_level < 10
)
select * from a
where value is not null
/

select * from pyramid;


select * from pyramid where history_id = 1;

select history_id, sum(value) the_sum
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff
group by history_id;

select sum(the_sum) from (
select history_id, sum(value) the_sum
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff
group by history_id
)
;
--still 2101134781, too low




create materialized view pyramid as 
with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from sequences
  
  union all
  
  select history_id, seq_num
    , value - lag(value,1) over (partition by history_id order by seq_num)
    , diff_level +1
  from a
  where diff_level < 25
)
select * from a
where value is not null
/

select * from pyramid where history_id = 1
order by seq_num, diff_level;

select history_id, diff_level
  , listagg(value,' ') within group (order by seq_num)
from pyramid where history_id = 1
group by history_id, diff_level
;

create or replace synonym input_data for day09_example;

BEGIN
DBMS_SNAPSHOT.REFRESH('SEQUENCES');
DBMS_SNAPSHOT.REFRESH('PYRAMID');
END;
/



select * from pyramid order by history_id, seq_num, diff_level;

select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
where history_id = 1
order by history_id, diff_level, seq_num
/
/*
"HISTORY_ID"	"SEQ_NUM"	"VALUE"	"DIFF_LEVEL"	"END_DIFF"
1	1	0	0	6
1	2	3	0	6
1	3	6	0	6
1	4	9	0	6
1	5	12	0	6
1	6	15	0	6
1	2	3	1	6
1	3	3	1	6
1	4	3	1	6
1	5	3	1	6
1	6	3	1	6
1	3	0	2	6
1	4	0	2	6
1	5	0	2	6
1	6	0	2	6
1	4	0	3	6
1	5	0	3	6
1	6	0	3	6
1	5	0	4	6
1	6	0	4	6
1	6	0	5	6
*/

select history_id, diff_level
  , listagg(value,' ') within group (order by seq_num)
  , min(seq_num), max(seq_num)
from pyramid where history_id = 1
group by history_id, diff_level
;
/*
"HISTORY_ID"	"DIFF_LEVEL"	"LISTAGG(VALUE,'')WITHINGROUP(ORDERBYSEQ_NUM)"	"MIN(SEQ_NUM)"	"MAX(SEQ_NUM)"
1	0	"0 3 6 9 12 15"	1	6
1	1	"3 3 3 3 3"	2	6
1	2	"0 0 0 0"	3	6
1	3	"0 0 0"	4	6
1	4	"0 0"	5	6
1	5	"0"	6	6
*/

-- not sure at this point, too late in the day