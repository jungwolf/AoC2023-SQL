-- Sample
create or replace synonym input_data for day01_part1;

/*
view dba_objects is used to get rows for rownum, it could have been any other existing table with 9+ rows
  could have created rows using a recursive view, too
*/

with text_numbers as (
-- view to create (1,'1'),(1,'one),(2,'2'),(2,'two) etc
  select
    rownum digit
    , lower(to_char(
        to_date(rownum,'j')
        --  rownum is used to represent julien year 1,2,3,etc.
        ,'JSP')
        --   JSP is an Oracle date format that spells out the year, one,two,three,etc.
      ) spelled_digit
  from dba_objects where rownum <= 9 -- just used to generate 9 rows for rownum
  union all
  select rownum digit
    , to_char(rownum) spelled_digit
  from dba_objects where rownum <= 9
)
, regex_search as (
-- creates a string '1|one|2|...' used by the regex search
  select
    listagg(spelled_digit,'|') within group (order by digit) all_digits
  from text_numbers
)
, first_last_text_numbers as (
-- search for the first number or spelled number
--   and last by starting at the end of the string
  select
    regexp_substr(i.linevalue,s.all_digits) first_text_num
    , reverse(regexp_substr(reverse(i.linevalue),reverse(s.all_digits))) last_text_num
  from input_data i, regex_search s
)
, first_last_numbers as (
--translates spelled number into digits
  select 
    t1.digit first_num, t2.digit second_num
  from first_last_text_numbers n,text_numbers t1,text_numbers t2
  where n.first_text_num = t1.spelled_digit
    and n.last_text_num = t2.spelled_digit
)
--construct the number, add them up
select sum(to_number(first_num||second_num)) from first_last_numbers
;

