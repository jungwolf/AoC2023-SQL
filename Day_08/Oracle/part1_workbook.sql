--works on example data, but taking a long time on part1
create or replace synonym input_data for day08_part1;

create or replace view number_of_instructions as
select length(linevalue) num
from input_data
where lineno = 1;
select * from number_of_instructions ;

create or replace view lr_instructions as
select
  n.id move_number
  , mod(n.id,x.num) mod_move
  , n.column_value direction
from input_data i, number_of_instructions x
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue))) n
where lineno = 1;
select * from lr_instructions;

create or replace view nodes as
select
  lineno id
--  ,linevalue
  ,regexp_substr(linevalue,'\w{3}',1,1) node
  ,regexp_substr(linevalue,'\w{3}',1,2) next_node_l
  ,regexp_substr(linevalue,'\w{3}',1,3) next_node_r
from input_data where lineno >= 3;
select * from nodes;

create or replace synonym input_data for day08_example1;
create or replace synonym input_data for day08_example2;
create or replace synonym input_data for day08_example3;

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
--    and m.move_number < 10
)
--select * from moves;
select count(*) from moves;

------------ so, how can we speed this up?
/*
we keep repeating the moves
can we use that to precompute somehow?

So, at least one node will reach Z within the sequence of moves
If I'm at a node, I can compute the last node at the end of a sequence of moves
  and mark it if Z is included
If I visit a node at the start of moves, I can't visit again at the start of moves or it results in a cycle
Call M number of moves and N number of nodes
If I precompute, I'll create N sequences of M moves, or N*M, or for my part1, about 700*340ish, or about 240k, not too bad

Although, that means my original algorythm should finish before 240k moves... So why is it taking so long?
Well, this thing certainly isn't effeciant.
Maybe work on that instead...
*/
create or replace synonym input_data for day08_example1;








----------- no, just optimization problem...
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
