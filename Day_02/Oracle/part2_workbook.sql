-- Sample
--create or replace synonym input_data for day??_part1;
--create or replace synonym input_data for day??_part2;

create or replace synonym input_data for day02_example;


select m.game_num, m.marble_color, max(m.num_marbles) required_marbles
from move_marbles m
group by m.game_num, m.marble_color
/


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


create or replace synonym input_data for day02_example;

select m.game_num, m.marble_color, max(m.num_marbles) required_marbles
from move_marbles m
group by m.game_num, m.marble_color
order by game_num, marble_color
/

select m.game_num, m.marble_color, max(m.num_marbles) required_marbles
from move_marbles m
group by m.game_num, m.marble_color
/

with max_color as (
select m.game_num, m.marble_color, max(to_number(m.num_marbles)) required_marbles
from move_marbles m
group by m.game_num, m.marble_color
)
select r.game_num, r.required_marbles*b.required_marbles*g.required_marbles
from max_color r,max_color b,max_color g
where
  r.game_num = b.game_num and b.game_num = g.game_num
  and r.marble_color='red'
  and b.marble_color='blue'
  and g.marble_color='green'
order by 1
/

-- whoops, still have num as char...
with max_color as (
  select m.game_num, m.marble_color, max(to_number(m.num_marbles)) required_marbles
  from move_marbles m
  group by m.game_num, m.marble_color
)
select
  sum(r.required_marbles*b.required_marbles*g.required_marbles) answer
from max_color r,max_color b,max_color g
where
  r.game_num = b.game_num and b.game_num = g.game_num
  and r.marble_color='red'
  and b.marble_color='blue'
  and g.marble_color='green'
/
/*
ANSWER
2286
*/
