/*
0 3 6 9 12 15
1 3 6 10 15 21
standard, parse the output
each line is a history of values, so call it history_id
the values are in order, separated by spaces
split out the values and keep their ordering (seq_num)
*/
create or replace view sequences as
select
  to_number(i.lineno) history_id
  , n.id seq_num
  , to_number(n.column_value) value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
select * from sequences;
/*
HISTORY_ID	SEQ_NUM	VALUE
1	1	0
1	2	3
1	3	6
*/

/*
building the pyramid of differences
0   3   6   9  12  15
  3   3   3   3   3
    0   0   0   0
i'm using diff_level to indicate the level of the pyramid
0 3 6 9 12 15 -- diff_level 0
  3 3 3  3  3 -- 1
    0 0  0  0 -- 3
      0  0  0 -- 4
         0  0 -- 5
            0 -- 6
not checking for all 0s, they shouldn't impact the answer
using lag() find the difference between _this_ value and the previous one
  lag() is null if previous row doesn't exist
  so "is not null" trims the output
  "where diff_level < 10" used to limit bugs causing 
*/
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
select * from pyramid where history_id = 1;

/*
HISTORY_ID	SEQ_NUM	VALUE	DIFF_LEVEL
1	1	0	0
1	2	3	0
1	3	6	0
1	2	3	1
1	3	3	1
1	3	0	2
...
*/
-- or putting it back together
select history_id
  , rpad(' ',4*diff_level)
    || listagg(to_char(value,'99'),' ') within group (order by seq_num)
  , diff_level
from pyramid
where history_id = 1
group by history_id,diff_level
;
/*
1	  0   3   6   9  12  15	0
1	      3   3   3   3   3	1
1	          0   0   0   0	2
1	              0   0   0	3
1	                  0   0	4
1	                      0	5
*/

select history_id, seq_num, value, diff_level
  , max(seq_num) over (partition by diff_level) end_diff
from pyramid where history_id = 1
order by history_id, seq_num, diff_level
/
/*
add up the last sql_num values for all diff_levels to get the answer
SEQ_NUM	VALUE	DIFF_LEVEL
...
6	15	0
6	3	1
6	0	2
6	0	3
6	0	4
6	0	5
*/

-- and sum them up to get the answer
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
