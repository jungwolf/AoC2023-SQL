-- something isn't right. start from the top
create or replace synonym input_data for day01_part2_example2;

create or replace view text_numbers as
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from user_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
/
-- oh! zero isn't one of the digits...
create or replace view text_numbers as
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from user_objects where rownum <= 9
/
select * from text_numbers;

-- but that didn't fix it.
-- 54414 is too low

create or replace view regex_search as
  select listagg(word,'|') within group (order by digit) digit_words
  from text_numbers
/
select * from regex_search
/
--one|two|three|four|five|six|seven|eight|nine
select
  i.lineno
  ,i.linevalue
  ,regexp_substr(i.linevalue,s.digit_words)
from input_data i, regex_search s
order by i.lineno
;
-- the idea is the regexp will pick up the first match
-- also, I'm relying on consistent behavior between regexp_substr and regexp_replace
-- is that valid?

, all_the_numbers (new_string, digit_to_replace) as (
  select
    i.linevalue
    ,regexp_substr(i.linevalue,s.digit_words)
  from input_data i, regex_search s

  union all

  select
    regexp_replace(new_string,digit_to_replace,t.digit,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),s.digit_words)
  from all_the_numbers i, text_numbers t, regex_search s
  where t.digit=digit_to_replace
  and digit_to_replace is not null
)

-- let's modify to show intermediate steps
with all_the_numbers (new_string, digit_to_replace, a_level) as (
  select
    i.linevalue
    ,regexp_substr(i.linevalue,'one|two|three|four|five|six|seven|eight|nine')
    ,0
  from input_data i

  union all

  select
    regexp_replace(new_string,digit_to_replace,t.digit,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),'one|two|three|four|five|six|seven|eight|nine')
    ,a_level + 1
  from all_the_numbers i, text_numbers t, regex_search s
  where t.word=digit_to_replace
  and (digit_to_replace is not null and a_level < 10)
)
select * from all_the_numbers;












with all_the_numbers (lineno, a_level, new_string, digit_to_replace, numdigits) as (
  select
    i.lineno
    ,0
    ,i.linevalue
    ,regexp_substr(i.linevalue,'one|two|three|four|five|six|seven|eight|nine')
    ,regexp_count(i.linevalue,'one|two|three|four|five|six|seven|eight|nine')
  from input_data i

  union all

  select
    lineno
    ,a_level + 1
    ,regexp_replace(new_string,digit_to_replace,t.digit,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),'one|two|three|four|five|six|seven|eight|nine')
    , regexp_count(regexp_replace(new_string,digit_to_replace,t.digit,1,1),'one|two|three|four|five|six|seven|eight|nine')
  from all_the_numbers i, text_numbers t, regex_search s
  where t.word=digit_to_replace
  and (digit_to_replace is not null and a_level < 10)
)
select *
from all_the_numbers
order by lineno, a_level;


with all_the_numbers (lineno, a_level, new_string, digit_to_replace, numdigits) as (
  select
    i.lineno
    ,0
    ,i.linevalue
    ,regexp_substr(i.linevalue,'one|two|three|four|five|six|seven|eight|nine')
    ,regexp_count(i.linevalue,'one|two|three|four|five|six|seven|eight|nine')
  from input_data i

  union all

  select
    lineno
    ,a_level + 1
    ,regexp_replace(new_string,digit_to_replace,t.digit,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),'one|two|three|four|five|six|seven|eight|nine')
    , regexp_count(regexp_replace(new_string,digit_to_replace,t.digit,1,1),'one|two|three|four|five|six|seven|eight|nine')
  from all_the_numbers i, text_numbers t, regex_search s
  where t.word=digit_to_replace
--  and (digit_to_replace is not null and a_level < 10)
  and numdigits > 0
)
--select *
select
  lineno
  ,a_level
  ,new_string
  ,digit_to_replace
  ,regexp_substr(new_string,'\d') d1
  ,regexp_substr(reverse(new_string),'\d') d2
  ,numdigits
from all_the_numbers
order by lineno, a_level;

-- i misunderstood the requirements, on to workbook3!