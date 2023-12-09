--create or replace synonym input_data for day08_part2_example1;
--select * from input_data;

select * from nodes where node like '__A';
-- 6
select * from nodes where node like '__Z';
-- 6

with moves(
    node, next_node_l, next_node_r
    , move_number
    , mod_move
    , direction
  ) as (
  select n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction direction
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
  union all
  select
    n.node
    , n.next_node_l, n.next_node_r
    , m.move_number+1
    , mod(m.move_number+1,i.num)
    , lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
    and n.node not like '__Z'
)
select * from moves where rownum < 10;


  select n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction direction
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
/


with moves(
    start_node, node, next_node_l, next_node_r
    , move_number
    , mod_move
    , direction
  ) as (
  select n.node start_node, n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction direction
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
  union all
  select
    m.start_node
    ,n.node
    , n.next_node_l, n.next_node_r
    , m.move_number+1
    , mod(m.move_number+1,i.num)
    , lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
    and n.node not like '__Z'
    and m.move_number < 100000
)
select 
    start_node
	||' '|| node
	||' '|| next_node_l
	||' '|| next_node_r
    ||' '|| move_number
    ||' '|| mod_move
    ||' '|| direction
from moves
order by start_node, move_number;

with moves(
    start_node, node, next_node_l, next_node_r
    , move_number
    , mod_move
    , direction
  ) as (
  select n.node start_node, n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction direction
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
  union all
  select
    m.start_node
    ,n.node
    , n.next_node_l, n.next_node_r
    , m.move_number+1
    , mod(m.move_number+1,i.num)
    , lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
    and n.node not like '__Z'
    and m.move_number < 1000000
)
select 
count(*)
from moves
/

-- does listagg work? yep!
with moves(
    start_node, node, next_node_l, next_node_r
    , move_number
    , mod_move
    , direction
	, at_stopper
	, aa
  ) as (
  select n.node start_node, n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction
    , 0
	, 'a'
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
  union all
  select
    m.start_node
    ,n.node
    , n.next_node_l, n.next_node_r
    , m.move_number+1
    , mod(m.move_number+1,i.num)
    , lr.direction
	, decode(substr(n.node,3,1),'Z',1,0)
	, listagg(m.node) over (partition by m.move_number)
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
--    and n.node not like '__Z'
    and m.node not like '__Z'
    and m.move_number < 100000
)
select 
*
from moves
/


with moves(
    start_node, node, next_node_l, next_node_r
    , move_number
    , mod_move
    , direction
	, at_stopper
  ) as (
  select n.node start_node, n.node, n.next_node_l, n.next_node_r
    , lr.move_number
    , lr.mod_move
    , lr.direction
    , 0
  from nodes n, lr_instructions lr, number_of_instructions i
  where n.node like '__A'
    and lr.mod_move = mod(1,i.num)
  union all
  select
    m.start_node
    ,n.node
    , n.next_node_l, n.next_node_r
    , m.move_number+1
    , mod(m.move_number+1,i.num)
    , lr.direction
--	, decode(substr(n.node,3,1),'Z',1,0)
	, sum(decode(substr(n.node,3,1),'Z',1,0)) over (partition by m.move_number)
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
--    and n.node not like '__Z'
--    and m.node not like '__Z'
    and m.at_stopper < 6
    and m.move_number < 100000
)
select 
--*
    start_node
	||' '|| node
	||' '|| next_node_l
	||' '|| next_node_r
    ||' '|| move_number
    ||' '|| mod_move
    ||' '|| direction
	||' '||at_stopper
from moves
where at_stopper > 0
order by start_node, move_number
/

-- okay, there is something here
-- try combining it with the precompute idea