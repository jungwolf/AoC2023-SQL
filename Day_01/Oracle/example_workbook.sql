-- scratchpad for creating the solution
create or replace synonym input_data for day01_example;

select * from input_data;

-- Sample
select linevalue firstnum, linevalue lastnum from input_data;
select linevalue firstnum, reverse(linevalue) lastnum from input_data;

select linevalue, regexp_substr(linevalue,'\d') from input_data;

-- I tried to do a regexp to get the last digit and couldnt. So just reverse the string...
select linevalue, regexp_substr(reverse(linevalue),'\d') from input_data;

select linevalue, regexp_substr(linevalue,'\d') firstnum, regexp_substr(reverse(linevalue),'\d') lastnum from input_data;
/*
LINEVALUE	FIRSTNUM	LASTNUM
1abc2	1	2
pqr3stu8vwx	3	8
a1b2c3d4e5f	1	5
treb7uchet	7	7
*/
select linevalue
  , regexp_substr(linevalue,'\d') firstnum
  , regexp_substr(reverse(linevalue),'\d') lastnum
  , to_number(regexp_substr(linevalue,'\d')||regexp_substr(reverse(linevalue),'\d')) calibration
from input_data;

select
  sum(to_number(regexp_substr(linevalue,'\d')||regexp_substr(reverse(linevalue),'\d'))) calibration_sum
from input_data;
/*
CALIBRATION_SUM
142
*/

-- worked on sample