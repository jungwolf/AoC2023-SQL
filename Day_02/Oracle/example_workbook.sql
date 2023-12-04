-- scratchpad for creating the solution
create or replace synonym input_data for day02_example;

select * from input_data;

-- using helper type and function
-- create or replace type varchar2_tbl as table of varchar2(4000);
-- create or replace function string2rows (p_string varchar2, p_delimiter varchar2 default null) return varchar2_tbl as

-- how does this work again?
select i.lineno, i.linevalue, '.', n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,':') )) n
;

-- get the game number and game line
select i.lineno
  , i.linevalue
  , instr(i.linevalue,' ')
  , instr(i.linevalue,':')
  , substr(i.linevalue,instr(i.linevalue,' ')+1,instr(i.linevalue,':')-instr(i.linevalue,' ')-1) game_num
  , substr(i.linevalue,instr(i.linevalue,':')+2) game_line
from input_data i
/
-- cleanup, shouldn't need orig values even for troubleshooting

select 
  substr(i.linevalue,instr(i.linevalue,' ')+1,instr(i.linevalue,':')-instr(i.linevalue,' ')-1) game_num
  , substr(i.linevalue,instr(i.linevalue,':')+2) game_line
from input_data i
/
/*
GAME_NUM	GAME_LINE
1	3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
2	1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
3	8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
4	1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
5	6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
*/

create or replace view games as 
select 
  substr(i.linevalue,instr(i.linevalue,' ')+1,instr(i.linevalue,':')-instr(i.linevalue,' ')-1) game_num
  , substr(i.linevalue,instr(i.linevalue,':')+2) game_line
from input_data i
/
select * from games;

create or replace view moves as
select g.game_num, g.game_line, n.id move_num, n.column_value move_line
from games g
  ,lateral(select rownum id, column_value from table( string2rows(g.game_line,'; ') )) n
/
select * from moves;

create or replace view move_parts as
select m.game_num, m.game_line, m.move_num, m.move_line, n.id part_num, n.column_value part_line
from moves m
  ,lateral(select rownum id, column_value from table( string2rows(m.move_line,', ') )) n
;
select *
from move_parts p
/

create or replace view move_marbles as
select p.game_num, p.game_line, p.move_num, p.move_line, p.part_num, p.part_line
--  ,instr(p.part_line,' ')
  ,substr(p.part_line,1,instr(p.part_line,' ')) num_marbles
  ,substr(p.part_line,instr(p.part_line,' ')) marble_color
from move_parts p
/

select game_num, move_num, part_num, num_marbles, marble_color from move_marbles ;

-- okay, all of that to parse the input, maybe overboard with the deconstruction...
exec drop_object_if_exists('day02_marble_bag','table');
create table day02_marble_bag (
  num_marbles number,
  marble_color varchar2(10)
);
--12 red cubes, 13 green cubes, and 14 blue cubes
-- oops, they are supposed to be cubes, fix later...
insert into day02_marble_bag (num_marbles, marble_color) values (12,'red');
insert into day02_marble_bag (num_marbles, marble_color) values (13,'green');
insert into day02_marble_bag (num_marbles, marble_color) values (14,'blue');

commit;
select * from day02_marble_bag;
-- maybe create a marble_bag synonym for part 2, who knows
-- ug, I don't use day02... for the views

exec drop_object_if_exists('day02_marble_bag','table');
exec drop_object_if_exists('marble_bag','table');
create table marble_bag (
  num_marbles number,
  marble_color varchar2(10)
);
--12 red cubes, 13 green cubes, and 14 blue cubes
-- oops, they are supposed to be cubes, fix later...
insert into marble_bag (num_marbles, marble_color) values (12,'red');
insert into marble_bag (num_marbles, marble_color) values (13,'green');
insert into marble_bag (num_marbles, marble_color) values (14,'blue');

commit;
select * from marble_bag;

--------------------------------------------------------------------------------------------------------
-- so now what?
-- match up move marbles with bag marbles

select m.game_num, m.move_num, m.part_num, m.num_marbles, m.marble_color
  , b.num_marbles max_marbles
from move_marbles m
  , marble_bag b
where m.marble_color = b.marble_color (+)
/
select * from marble_bag;
-- whoops, kept an extra space in move_marbles
create or replace view move_marbles as
select p.game_num, p.game_line, p.move_num, p.move_line, p.part_num, p.part_line
--  ,instr(p.part_line,' ')
  ,substr(p.part_line,1,instr(p.part_line,' ')) num_marbles
  ,substr(p.part_line,instr(p.part_line,' ')+1) marble_color
from move_parts p
/

select m.game_num, m.move_num, m.part_num, m.num_marbles, m.marble_color
  , b.num_marbles max_marbles
from move_marbles m
  , marble_bag b
where m.marble_color = b.marble_color (+)
/

select m.game_num, m.move_num, m.part_num, m.num_marbles, m.marble_color
  , b.num_marbles max_marbles
  , nvl(b.num_marbles - m.num_marbles,-999) extra_marbles
from move_marbles m
  , marble_bag b
where m.marble_color = b.marble_color (+)
/

select m.game_num, m.move_num, m.part_num, m.num_marbles, m.marble_color
  , b.num_marbles max_marbles
  , nvl(b.num_marbles - m.num_marbles,-999) marbles_remaining
from move_marbles m
  , marble_bag b
where m.marble_color = b.marble_color (+)
/

select m.game_num
  , min(nvl(b.num_marbles - m.num_marbles,-999)) min_marbles_remaining
from move_marbles m
  , marble_bag b
where m.marble_color = b.marble_color (+)
group by m.game_num
/

select sum (game_num) answer
from (
  select m.game_num
    , min(nvl(b.num_marbles - m.num_marbles,-999)) min_marbles_remaining
  from move_marbles m
    , marble_bag b
  where m.marble_color = b.marble_color (+)
  group by m.game_num
)
where min_marbles_remaining >=0
/
/*
ANSWER
8
*/
