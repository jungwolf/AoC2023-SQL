create or replace synonym input_data for day09_part1;

-- ug. I had the answer going forward, just needed to reverse the sequence numbers
-- row_number() gives me the current row number ordered in whatever way, not just as they are returned

with sequences as (
  select /*+ materialize */
    to_number(i.lineno) history_id
    , row_number() over (partition by to_number(i.lineno) order by id desc) seq_num
    , to_number(n.column_value) value
  from input_data i
    ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
)
, pyramid (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from sequences

  union all

  select history_id, seq_num
    , value - lag(value,1) over (partition by history_id order by seq_num)
    , diff_level +1
  from pyramid
  where value is not null
)
select sum(value) the_sum
from (
  select seq_num, value, diff_level
    , max(seq_num) over (partition by diff_level) end_diff
  from pyramid
)
where seq_num = end_diff
/
