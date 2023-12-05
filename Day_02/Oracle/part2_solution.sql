-- Sample
--create or replace synonym input_data for day??_part2;
create or replace synonym input_data for day02_part1;

-- unlike addition, oracle doesn't have an aggregate function for multiply
-- three colors, just brute force it
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
