-- Sample
create or replace synonym input_data for day01_part1;

--let's see if the example solution works
select
  sum(to_number(regexp_substr(linevalue,'\d')||regexp_substr(reverse(linevalue),'\d'))) calibration_sum
from input_data;
/*
CALIBRATION_SUM
55477
*/
-- yep