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

create or replace synonym input_data for day08_part1;
