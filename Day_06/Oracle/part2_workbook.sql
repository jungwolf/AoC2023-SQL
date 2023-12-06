-- Sample
--create or replace synonym input_data for day??_part1;
--create or replace synonym input_data for day??_part2;

create or replace synonym input_data for day06_example;


-- basically need to remove the extra spaces to get the corrected output
create or replace view input_data_no_spaces as select lineno, replace(linevalue,' ') linevalue from input_data;

-- since spaces are gone, splitting on the ':'
create or replace view parse1 as
select i.lineno, i.linevalue, n.id, n.column_value
from input_data_no_spaces i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,':')) where column_value is not null) n
;

-- um, that should do it? assuming we don't need to optimize...
select * from parse1;
select * from races;
-- going to be a lot, so just counting...
select count(*) from races_by_hold_time;

-- shocking ran out of memory
select * from races;
/*
RACE_ID	TIME	DISTANCE
2	59688274	543102016641022
*/
-- remember distance is hold_seconds * (time-hold_seconds)
-- s*t-s*s
select LOG(2,543102016641022) from dual;
select time, distance, (time/2)*(time-time/2) from races;
-- thats a win, maybe binary search from there both up and down

-- hmm, d=h*t-h*h; h*t=d+h*h; t=(d+h*h)/h; t=d/h+h
-- d=h*t-h*h; h^2-th-d=0; a=1, b=-t, c=-d; h=(-t +- sqrt(-t*-t-4*-d))/2

-- less than this, hold gives a loss
select (time + sqrt(time*time-4*(distance))  )/2 from races;
-- greater than this, hold gives a loss
select (time - sqrt(time*time-4*(distance))  )/2 from races;

select trunc((time + sqrt(time*time-4*(distance)))/2+0.5) from races;
select trunc((time - sqrt(time*time-4*(distance)))/2) from races;

select 
  ,trunc((time + sqrt(time*time-4*(distance)))/2+0.5) first_winning_race
  ,trunc((time - sqrt(time*time-4*(distance)))/2) last_winning_race
  ,trunc((time - sqrt(time*time-4*(distance)))/2) - trunc((time + sqrt(time*time-4*(distance)))/2+0.5) diff
  ,trunc((time - sqrt(time*time-4*(distance)))/2) - trunc((time + sqrt(time*time-4*(distance)))/2+0.5) + 1 num_in_interval
from races;

select
  trunc((time - sqrt(time*time-4*(distance)))/2) first_winning_race
  ,trunc((time + sqrt(time*time-4*(distance)))/2+0.5) last_winning_race
  ,trunc((time + sqrt(time*time-4*(distance)))/2+0.5) - trunc((time - sqrt(time*time-4*(distance)))/2) diff
  ,trunc((time + sqrt(time*time-4*(distance)))/2+0.5) - trunc((time - sqrt(time*time-4*(distance)))/2)+1 num_in_interval
from races;
-- interval = answer?
--your answer is too high

-- d=h*t-h*h
-- h^2+d=h*t
-- h^2-t*h+d=0; a=1, b=-t, c=d
-- h=(-b +- sqrt(b*b-4*a*c))/2a
-- h=(-(-t) +- sqrt((-t)*(-t)-4*1*d))/2*1
-- (-(-time) +- sqrt((-time)*(-time)-4*1*distance))/2*1
-- (time +- sqrt(time*time-4*distance))/2
select
(time - sqrt(time*time-4*distance))/2
,(time + sqrt(time*time-4*distance))/2
from races;

select
   round((time - sqrt(time*time-4*distance))/2+0.5) first_winning_race
  ,trunc((time + sqrt(time*time-4*distance))/2)   last_winning_race
  ,  trunc((time + sqrt(time*time-4*distance))/2)
   - round((time - sqrt(time*time-4*distance))/2+0.5) diff
  ,  trunc((time + sqrt(time*time-4*distance))/2)
   - round((time - sqrt(time*time-4*distance))/2+0.5)
   +1  num_in_interval
from races;
-- okay, num_in_interal is right