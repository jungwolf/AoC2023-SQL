-- using materialized views, so have to recreate them if changing sysnonym...
create or replace synonym input_data for day08_part1;

exec drop_object_if_exists('number_of_instructions','view');
exec drop_object_if_exists('number_of_instructions','materialized view');
create materialized view number_of_instructions as
select length(linevalue) num
from input_data
where lineno = 1;
select * from number_of_instructions ;

exec drop_object_if_exists('lr_instructions','view');
exec drop_object_if_exists('lr_instructions','materialized view');
create materialized view lr_instructions as
select
  n.id move_number
  , mod(n.id,x.num) mod_move
  , n.column_value direction
from input_data i, number_of_instructions x
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue))) n
where lineno = 1;
select * from lr_instructions;

exec drop_object_if_exists('nodes','view');
exec drop_object_if_exists('nodes','materialized view');
create materialized view nodes as
select
  lineno id
--  ,linevalue
  ,regexp_substr(linevalue,'\w{3}',1,1) node
  ,regexp_substr(linevalue,'\w{3}',1,2) next_node_l
  ,regexp_substr(linevalue,'\w{3}',1,3) next_node_r
from input_data where lineno >= 3;
select * from nodes;

create index node_idx on nodes(node);

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
  where n.node = 'AAA'
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
    and n.node != 'ZZZ'
)
select count(*) from moves;

with moves (
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
    and m.move_number <= 100000
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
where at_stopper > 1
order by move_number desc, start_node fetch first 12 rows only
/

select * from nodes;
select * from nodes where node = 'AAA';
select * 
from nodes, lr_instructions
where node = 'AAA';

with moves (
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
  where 1=1
--    and n.node like 'AAA'
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
--	, sum(decode(substr(n.node,3,1),'Z',1,0)) over (partition by m.move_number)
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
--    and n.node not like '__Z'
--    and m.node not like '__Z'
    and m.mod_move != 0 
    and m.move_number <= 100000
)
select 
--    start_node||' '|| node||' '|| next_node_l||' '|| next_node_r||' '|| move_number||' '|| mod_move||' '|| direction||' '||at_stopper
*
from moves
-- let's see the stoppers
where at_stopper =1
/
-- this is odd
-- let's look at a known stopper

select * from nodes n where decode(substr(n.node,3,1),'A',1,0) = 1;
/*
42	SLA	HLN	TMV
130	AAA	QRH	FRS
254	LVA	QDM	DVP
312	NPA	FCJ	NPF
324	GDA	LGN	DDC
534	RCA	KPB	DXV
*/
select * from nodes n where decode(substr(n.node,3,1),'Z',1,0) = 1;
/*
164	RPZ	TMV	HLN
367	ZZZ	FRS	QRH
504	STZ	DDC	LGN
646	CMZ	DXV	KPB
654	SFZ	DVP	QDM
679	HKZ	NPF	FCJ
*/
select * from nodes n where decode(substr(n.next_node_l,3,1),'Z',1,0) = 1;
select * from nodes n where decode(substr(n.next_node_r,3,1),'Z',1,0) = 1;
-- interesting, all stoppers are on R
-- okay, check for JHQ

with moves (
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
  where 1=1
    and n.node like 'JHQ'
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
--	, sum(decode(substr(n.node,3,1),'Z',1,0)) over (partition by m.move_number)
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
--    and n.node not like '__Z'
--    and m.node not like '__Z'
    and m.mod_move != 0 
    and m.move_number <= 100000
)
select 
--    start_node||' '|| node||' '|| next_node_l||' '|| next_node_r||' '|| move_number||' '|| mod_move||' '|| direction||' '||at_stopper
*
from moves
-- let's see the stoppers
--where at_stopper =1
/

-- okay...

with moves (
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
  where 1=1
    and n.node like 'SLA'
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
--	, sum(decode(substr(n.node,3,1),'Z',1,0)) over (partition by m.move_number)
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node
    and lr.mod_move = mod(m.move_number+1,i.num)
--    and n.node not like '__Z'
--    and m.node not like '__Z'
--    and m.mod_move != 0 
    and m.at_stopper = 0
    and m.move_number <= 100000
)
select 
--    start_node||' '|| node||' '|| next_node_l||' '|| next_node_r||' '|| move_number||' '|| mod_move||' '|| direction||' '||at_stopper
*
from moves
-- let's see the stoppers
--where at_stopper =1
/
-- works to get to first stopper
-- and always the same stopper?
/*
SLA	RPZ	TMV	HLN	11654	1	L	1
SLA	RPZ	TMV	HLN	23307	1	L	1 diff 11653
SLA	RPZ	TMV	HLN	34960	1	L	1 diff 11653
*/