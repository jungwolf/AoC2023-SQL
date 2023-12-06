-- example solution worked as-is
create or replace synonym input_data for day06_part1;

-- split on ' ', remove empty rows when there are consecutive ' '
-- lineno 1 has the times, lineno2 has the corresponding distance
create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,' ')) where column_value is not null) n
;
/*
LINENO	LINEVALUE	ID	COLUMN_VALUE
1	Time:      7  15   30	1	Time:
1	Time:      7  15   30	2	7
...			
2	Distance:  9  40  200	1	Distance:
2	Distance:  9  40  200	2	9
...
*/

/*
using pivot
- pivot groups by the values _not_ in the aggregate function(s); it's an implicit group
- need to remove any extraneous columns to avoid error causing groups.. (just lineno, id, column_value in this case)
- after the group columns, adds columns for (#values in for clause)*(# of aggregates), named by concatenating invaluealias_aggregatealias
-   in this case, 1x2, adds one column for time_cv and one for distance_cv
remove id 1 because the race values come after a line header..
given 'Time:      7  15   30', the first value Time: is the header..
*/
create or replace view races as
select id race_id, time_cv time, distance_cv as distance
from (select lineno, id, column_value from parse1)
pivot ( max(column_value) as cv for lineno in (1 as Time,2 as distance))
where id != 1;
/*
RACE_ID	TIME	DISTANCE
2	7	9
3	15	40
4	30	200
*/

-- use lateral join to generate time number of rows for a specific race
-- add an extra row for 0
create or replace view races_by_hold_time as
select r.race_id, r.time, r.distance record_distance, n.hold_seconds
from races r
  , lateral(select level-1 hold_seconds from dual connect by level <= r.time+1) n;
/*
RACE_ID	TIME	RECORD_DISTANCE	HOLD_SECONDS
2	7	9	0
2	7	9	1
2	7	9	2
2	7	9	3
...
RACE_ID	TIME	RECORD_DISTANCE	HOLD_SECONDS
3	15	40	14
3	15	40	15
4	30	200	0
4	30	200	1
...
*/

-- counts the number of winning races for a race_id
-- then multiplies them together
-- ug, using log/exp as PRODUCT() since oracle doesn't have one
--  ... EXP(SUM(LN(column)))
select round(EXP(SUM(LN(the_count)))) answer
from (
  select count(*) the_count
  from races_by_hold_time t
  where t.record_distance < (time-hold_seconds)*hold_seconds
  group by race_id
);
