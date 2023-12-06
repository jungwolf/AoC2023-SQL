create or replace synonym input_data for day06_example;

create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,' ')) where column_value is not null) n
;

-- remove id 1 because the race values come after a line header..
-- given 'Time:      7  15   30', the first value Time: is the header..
create or replace view races as
select id race_id, time_cv time, distance_cv as distance
from (select lineno, id, column_value from parse1)
pivot ( max(column_value) as cv for lineno in (1 as Time,2 as distance))
where id != 1;

-- use lateral join to generate time number of rows for a specific race
-- add an extra row for 0
create or replace view races_by_hold_time as
select r.race_id, r.time, r.distance record_distance, n.hold_seconds
from races r
  , lateral(select level-1 hold_seconds from dual connect by level <= r.time+1) n;

-- ug, using logs as PRODUCT() standing... EXP(SUM(LN(column)))
select round(EXP(SUM(LN(the_count)))) answer
from (
  select count(*) the_count
  from races_by_hold_time t
  where t.record_distance < (time-hold_seconds)*hold_seconds
  group by race_id
);
