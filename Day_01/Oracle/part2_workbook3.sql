-- misunderstood, eightwowo is both 8twowo and eight2wo

--\d(?![\s\S]*\d)
--one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9
--[one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9](?![one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9])
--(one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9) (?![\s\S]* (one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9) )
--(one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9)(?!.*(one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9))

create or replace synonym input_data for day01_part2_example2;

with text_numbers as (
  select rownum digit
    , lower(to_char(to_date(rownum,'j'),'JSP')) word
    , to_char(rownum)||lower(substr(to_char(to_date(rownum,'j'),'JSP'),2)) replace_word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
, all_the_numbers (new_string, digit_to_replace, a_level) as (
  select
    i.linevalue
    ,regexp_substr(i.linevalue,s.digit_words)
    ,0
  from input_data i, regex_search s

  union all

  select
    regexp_replace(new_string,digit_to_replace,t.replace_word,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),s.digit_words)
    ,a_level + 1
  from all_the_numbers i, text_numbers t, regex_search s
  where t.word=digit_to_replace
  and (digit_to_replace is not null and a_level < 10)
)
, fixed_numbers as (select new_string from all_the_numbers where digit_to_replace is null)
select
  sum(to_number(regexp_substr(new_string,'\d')||regexp_substr(reverse(new_string),'\d'))) calibration_sum
from fixed_numbers;
