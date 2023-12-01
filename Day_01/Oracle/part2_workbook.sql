-- like normal, input is still the same as part1
create or replace synonym input_data for day02_part1;

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
