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

-- oh, no multiplying, so that's the answer
select count(*) answer from races_by_hold_time;

