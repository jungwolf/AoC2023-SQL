-- Sample
create or replace synonym input_data for day02_part1;

-- created a table to hold the constraints
select * from marble_bag;
/*
NUM_MARBLES	MARBLE_COLOR
12	red
13	green
14	blue
*/ 


-- going with views this time, easier to debug...

/* parse, pull out (game number, remaining line)
GAME_NUM	GAME_LINE
1	3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
2	1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
*/
create or replace view games as 
select 
  substr(i.linevalue,instr(i.linevalue,' ')+1,instr(i.linevalue,':')-instr(i.linevalue,' ')-1) game_num
  , substr(i.linevalue,instr(i.linevalue,':')+2) game_line
from input_data i
/

/* parse, pull out "moves"
GAME_NUM	MOVE_NUM	MOVE_LINE
1	1	3 blue, 4 red
1	2	1 red, 2 green, 6 blue
*/
create or replace view moves as
select g.game_num, g.game_line, n.id move_num, n.column_value move_line
from games g
  ,lateral(select rownum id, column_value from table( string2rows(g.game_line,'; ') )) n
/

/* parse, get marbles in a move, number and color still together
GAME_NUM	MOVE_NUM	PART_NUM	PART_LINE
1	1	1	3 blue
1	1	2	4 red
1	2	1	1 red
1	2	2	2 green
1	2	3	6 blue
*/
create or replace view move_parts as
select m.game_num, m.game_line, m.move_num, m.move_line, n.id part_num, n.column_value part_line
from moves m
  ,lateral(select rownum id, column_value from table( string2rows(m.move_line,', ') )) n
;

/* parse, split out color and number
GAME_NUM	MOVE_NUM	PART_NUM	NUM_MARBLES	MARBLE_COLOR
1	1	1	3 	blue
1	1	2	4 	red
1	2	1	1 	red
1	2	2	2 	green
1	2	3	6 	blue
1	3	1	2 	green
*/
create or replace view move_marbles as
select p.game_num, p.game_line, p.move_num, p.move_line, p.part_num, p.part_line
--  ,instr(p.part_line,' ')
  ,substr(p.part_line,1,instr(p.part_line,' ')) num_marbles
  ,substr(p.part_line,instr(p.part_line,' ')) marble_color
from move_parts p
/

/* throw it all together
using colors, match maximum number of marbles to marbles in a move
use that to find the marbles left over from the bag
group by the games, take the minimum marbles remaining (negative means too many)
add up the game numbers for non-negative games
*/

select sum(game_num) answer
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
3059
*/
