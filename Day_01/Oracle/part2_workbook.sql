-- like normal, input is still the same as part1
create or replace synonym input_data for day01_example;

-- basically, need to replace spelled out numbers with the digit
-- the replace() function does that

-- so date format convertion can do a lot you wouldn't expect
-- for example, the jsp format spells out the date
-- and j is julian date
select to_date(1,'j') from dual;
-- 1/1/4712
select to_char(to_date(1,'j'),'JSP') from dual;
-- ONE

-- can we use that as a translation table, instead of building it up?
-- not quite, it can't handle 0
select rownum-1, to_char(to_date(rownum-1,'j'),'JSP') from dba_objects where rownum <= 10;
-- ORA-01854: julian date must be between 1 and 5373484

select rownum, to_char(to_date(rownum,'j'),'JSP') from dba_objects where rownum <= 9
union all
select 0, 'ZERO' from dual;
-- one union, not too bad

-- the input is lower-case
with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
select * from text_numbers;
/*
DIGIT	WORD
1	one
2	two
3	three
4	four
5	five
6	six
7	seven
8	eight
9	nine
0	zero
*/

-- oh, example input doesn't have any words, so use example from part2 description
exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day01_part2_example','table');
create table day01_part2_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day01_part2_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'two1nine');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'eightwothree');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'abcone2threexyz');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'xtwone3four');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'4nineeightseven2');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'zoneight234');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'7pqrstsixteen');

-- don't regress
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'1abc2');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'pqr3stu8vwx');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'a1b2c3d4e5f');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'treb7uchet');

commit;

with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
select i.linevalue, t.word, t.digit, replace(i.linevalue, t.word, t.digit)
from input_data i, text_numbers t;
/*
...
LINEVALUE	WORD	DIGIT	REPLACE(I.LINEVALUE,T.WORD,T.DIGIT)
xtwone3four	four	4	xtwone34
7pqrstsixteen	six	6	7pqrst6teen
...
*/

-- guess it is time to get recursive

with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, all_the_numbers (replaced_digit, new_string) as (
  select t.digit replaced_digit, replace(i.linevalue, t.word, t.digit) new_string
  from input_data i, text_numbers t
  where t.digit=0
  
  union all
  
  select t.digit, replace(new_string, t.word, t.digit) new_string
  from all_the_numbers i, text_numbers t
  where t.digit=replaced_digit+1
  and replaced_digit < 10
)  
select * from all_the_numbers;
-- besides a typo for t.t.digit, worked first try!
/*
REPLACED_DIGIT	NEW_STRING
0	two1nine
0	eightwothree
0	abcone2threexyz
...	
9	219
9	eigh23
9	abc123xyz
...
*/
-- oh, except eightwothree should be 8wo3...
-- search for possible digits, find lowest instr value, use it, iterate? Ug...

-- okay, use REGEXP_SUBSTR and one|two|... to get the string, then replace using that string...
-- getting search string...

with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) from text_numbers
)
select * from regex_search;


with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
select
  i.linevalue
  ,regexp_substr(i.linevalue,s.digit_words)
from input_data i, regex_search s
;

-- okay, in the right direction
/*
LINEVALUE	REGEXP_SUBSTR(I.LINEVALUE,S.DIGIT_WORDS)
two1nine	two
eightwothree	eight
abcone2threexyz	one
xtwone3four	two
4nineeightseven2	nine
zoneight234	one
7pqrstsixteen	six
1abc2	
pqr3stu8vwx	
a1b2c3d4e5f	
treb7uchet	
*/


-- crazy try...
with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
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
select * from all_the_numbers;

-- small correction
with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
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
  where t.word=digit_to_replace
  and digit_to_replace is not null
)
select *
from all_the_numbers
where digit_to_replace is null;




--- so plug that back into solution 1...
select
  sum(to_number(regexp_substr(linevalue,'\d')||regexp_substr(reverse(linevalue),'\d'))) calibration_sum
from input_data;

with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
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
  where t.word=digit_to_replace
  and digit_to_replace is not null
)
, fixed_numbers as (select new_string from all_the_numbers where digit_to_replace is null)
select * from fixed_numbers;


with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
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
  where t.word=digit_to_replace
  and digit_to_replace is not null
)
, fixed_numbers as (select new_string from all_the_numbers where digit_to_replace is null)
select
  sum(to_number(regexp_substr(new_string,'\d')||regexp_substr(reverse(new_string),'\d'))) calibration_sum
from fixed_numbers;

-- so lets see if it works...
--create or replace synonym input_data for day01_example;
create or replace synonym input_data for day01_part1;

-- no, hit ORA-32044: cycle detected while executing recursive WITH query
-- 6	ninetwonine234nvtlzxzczx	not sure what is up with that.. kinda looks like it is just watching the digit_to_replace column
-- adding a_level stops the error but not sure why the error was there in the first place

with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
  from dba_objects where rownum <= 9

  union all

  select 0, 'zero' from dual
)
, regex_search as (
  select listagg(word,'|') within group (order by digit) digit_words from text_numbers
)
, all_the_numbers (new_string, digit_to_replace, a_level) as (
  select
    cast(i.linevalue as varchar2(100))
    ,regexp_substr(i.linevalue,s.digit_words)
    , 0
  from input_data i, regex_search s
  where i.lineno = 6

  union all

  select
    regexp_replace(new_string,digit_to_replace,t.digit,1,1)
    , regexp_substr(regexp_replace(new_string,digit_to_replace,t.digit,1,1),s.digit_words)
    ,a_level + 1
  from all_the_numbers i, text_numbers t, regex_search s
  where t.word=digit_to_replace
  and (digit_to_replace is not null and a_level < 10)
)
select * from all_the_numbers
;


with text_numbers as (
  select rownum digit, lower(to_char(to_date(rownum,'j'),'JSP')) word
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
    regexp_replace(new_string,digit_to_replace,t.digit,1,1)
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


-- okay, try it with just the examples from part 2
exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day01_part2_example2','table');
create table day01_part2_example2 (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day01_part2_example2;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'two1nine');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'eightwothree');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'abcone2threexyz');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'xtwone3four');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'4nineeightseven2');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'zoneight234');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'7pqrstsixteen');

commit;

--hmm, that works...

-- going to a new workbook for debugging
