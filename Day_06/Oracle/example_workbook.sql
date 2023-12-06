-- scratchpad for creating the solution
create or replace synonym input_data for day06_example;

select * from input_data;
/*
LINENO	LINEVALUE
1	Time:      7  15   30
2	Distance:  9  40  200
*/

-- Sample
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,':') )) n;

create view parse1 as 
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,':') )) n;
select * from parse1;

-- no need to split out time or distance
create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,' ') )) n
where n.column_value is not null;
select * from parse1;
/*
LINENO	LINEVALUE	ID	COLUMN_VALUE
1	Time:      7  15   30	1	Time:
1	Time:      7  15   30	7	7
1	Time:      7  15   30	9	15
1	Time:      7  15   30	12	30
2	Distance:  9  40  200	1	Distance:
2	Distance:  9  40  200	3	9
2	Distance:  9  40  200	5	40
2	Distance:  9  40  200	7	200
*/
-- get rid of empty lines
create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,' ')) where column_value is not null) n
;
select lineno, id, column_value from parse1;
/*
LINENO	ID	COLUMN_VALUE
1	1	Time:
1	2	7
1	3	15
1	4	30
2	1	Distance:
2	2	9
2	3	40
2	4	200
*/

-- i hate pivots...
-- remove id 1 because the race values come after a line header..
-- given 'Time:      7  15   30', the first value Time: is the header..
create or replace view races as
select id race_id, time_cv time, distance_cv as distance
from (select lineno, id, column_value from parse1)
pivot ( max(column_value) as cv for lineno in (1 as Time,2 as distance))
where id != 1;
select * from races;
/*
RACE_ID	TIME	DISTANCE
2	7	9
3	15	40
4	30	200
*/
