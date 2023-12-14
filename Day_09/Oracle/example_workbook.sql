-- scratchpad for creating the solution
create or replace synonym input_data for day09_example;

select * from input_data;


-- clear out any overlapping names...
exec drop_object_if_exists('sequences','materialized view');
exec drop_object_if_exists('pyramid','materialized view');

-- get the elements
select
  i.lineno history_id
  , n.id seq_num
  , n.column_value value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
/* so, histories are basically this:
x, x+y, x+y+z, x+y+z, x+y+z... while the new element is > 0
oh, that's diff, so normalize the sequence to 0

-- no
let's call the list X and elements are numbered x(0), x(1), x(2), ...
Let c=x(0)
Then X -> c, (x(1)-c)+c, (x(2)-c)+c, ...
and we can "take out" c for X' -> 0, x(1), x(2), ...

I guess more x(0)+c,x(0)+x(1)+c, x(0)+x(1)+x(2)+c .. while x(n) > 0
where c=x, x(0) = 0, x(1) = y, and x(n+1)=x(n)-x(n-1) while x(n) > 0

check:
0 3 6 9 12 15
c=0, x(1)=3
*/
-- whatever, let's look at the first line
create or replace view seq_line_1 as 
select
  i.lineno history_id
  , n.id seq_num
  , n.column_value value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
where i.lineno = 1
;
select * from seq_line_1;
/*
"HISTORY_ID"	"SEQ_NUM"	"VALUE"
1	1	"0"
1	2	"3"
1	3	"6"
1	4	"9"
1	5	"12"
1	6	"15"

can we find the diffs all the way up the pyramid?
0   3   6   9  12  15
  3   3   3   3   3
    0   0   0   0
but ignore if they are all 0 because that's an extra test
*/
with a (history_id, seq_num, column_value, diff_level) as (
  select history_id, seq_num, column_value, 0
  from seq_line_1
  
  union all
  
  select history, seq_num
    , lag(value,1) over (order by seq_num) - value
    , diff_level +1
  from a
  where diff_level < 10
)
select * from a;

------
create or replace view seq_line_1 as 
select
  to_number(i.lineno) history_id
  , n.id seq_num
  , to_number(n.column_value) value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
where i.lineno = 1
;
select * from seq_line_1;

with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from seq_line_1
  
  union all
  
  select history_id, seq_num
    , lag(value,1) over (order by seq_num) - value
    , diff_level +1
  from a
  where diff_level < 10
)
select * from a;

---
with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from seq_line_1
  
  union all
  
  select history_id, seq_num
    , value - lag(value,1) over (order by seq_num)
    , diff_level +1
  from a
  where diff_level < 10
    and value is not null
)
select * from a;
/*
HISTORY_ID	SEQ_NUM	VALUE	DIFF_LEVEL
1	1	0	0
1	2	3	0
1	3	6	0
1	4	9	0
1	5	12	0
1	6	15	0
1	1		1
1	2	3	1
1	3	3	1
1	4	3	1
1	5	3	1
1	6	3	1
1	2		2
1	3	0	2
1	4	0	2
1	5	0	2
1	6	0	2
1	3		3
1	4	0	3
1	5	0	3
1	6	0	3
1	4		4
1	5	0	4
1	6	0	4
1	5		5
1	6	0	5
1	6		6
*/

create or replace view pyramid as 
with a (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from seq_line_1
  
  union all
  
  select history_id, seq_num
    , value - lag(value,1) over (order by seq_num)
    , diff_level +1
  from a
  where diff_level < 10
--    and value is not null
)
select * from a
where value is not null;
select * from pyramid;

select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level)
from pyramid;

select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid;

select history_id, value, diff_level, end_diff
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff;

select sum(value)
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid
)
where seq_num = end_diff;
-- 18
-- um, I think I know why, but explaining it...
-- all of the last diffs plus the last seq number gives the next seq number...

create or replace view sequences as 
select
  i.lineno history_id
  , n.id seq_num
  , n.column_value value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
select * from sequences;

create or replace view sequences as 
select
  to_number(i.lineno) history_id
  , n.id seq_num
  , to_number(n.column_value) value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
select * from sequences;


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
;

create or replace view pyramid as 
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

select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by history_id, diff_level) end_diff
from pyramid
/

select history_id, value, diff_level, end_diff
from (
select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by history_id, diff_level) end_diff
from pyramid
)
where seq_num = end_diff;

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

