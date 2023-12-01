-- Sample
create or replace synonym input_data for day01_example;

/*
regex to find the first digit
regex on the reverse string to find the last digit
concate the two
convert to number
add them up
*/

select
  sum(to_number(regexp_substr(linevalue,'\d')||regexp_substr(reverse(linevalue),'\d'))) calibration_sum
from input_data;
/*
CALIBRATION_SUM
142
*/
