-- Sample
--create or replace synonym input_data for day??_part1;

create or replace synonym input_data for day02_part1;

-- no change, worked

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



