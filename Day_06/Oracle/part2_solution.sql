-- example solution worked as-is
create or replace synonym input_data for day06_part1;

-- need to remove the extra spaces to get the corrected input
create or replace view input_data_no_spaces as select lineno, replace(linevalue,' ') linevalue from input_data;

-- since spaces are gone, splitting on the ':'
-- almost the same code as part1, results in one race
-- lineno 1 has the time, lineno2 has the distance
create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data_no_spaces i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,':')) where column_value is not null) n
;

-- same code as part1
create or replace view races as
select id race_id, time_cv time, distance_cv as distance
from (select lineno, id, column_value from parse1)
pivot ( max(column_value) as cv for lineno in (1 as Time,2 as distance))
where id != 1;
/*
RACE_ID	TIME	DISTANCE
2	71530	940200
*/

/*
generating all the moves is far too expensive, gotta be smarter
remember observation from example workbench?
  -- so distance is hold_seconds * (time-hold_seconds)
So our holding beats the record distance when:
  hold_seconds * (time-hold_seconds) - record_distance > 0
  or: hold_seconds*time - (hold_seconds*hold_seconds) - record_distance > 0
  or: hold_seconds*hold_seconds - hold_seconds*time + record_distance > 0
That's a quadratic equation. The zeros are
  hold_seconds = (time +- sqrt(time*time-4*distance))/2
We need the number of seconds between those zeros.
  Keep in mind we're only looking at whole numbers (seconds).
  So round up from the first zero, round down from the last zero
Moving things around to accomodate sql notation gives us this!
*/
select
   round((time - sqrt(time*time-4*distance))/2+0.5) first_winning_race
  ,trunc((time + sqrt(time*time-4*distance))/2)   last_winning_race
  ,  trunc((time + sqrt(time*time-4*distance))/2)
   - round((time - sqrt(time*time-4*distance))/2+0.5) diff
  ,  trunc((time + sqrt(time*time-4*distance))/2)
   - round((time - sqrt(time*time-4*distance))/2+0.5)
   +1  num_in_interval
from races;
-- okay, num_in_interal is the answer!

