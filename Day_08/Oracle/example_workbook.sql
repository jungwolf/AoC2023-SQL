create or replace synonym input_data for day08_example1;

select * from input_data;

select * from input_data where lineno = 1;

-- extract the move instructions
create or replace view lr_instructions as
select * from input_data where lineno = 1;
select * from lr_instructions;

select * from input_data where lineno >= 3;
-- split yada yada, let's just grab the three words directly with regex
select
  lineno
  ,linevalue
  ,regexp_substr(linevalue,'\w{3}',1,1) w1
  ,regexp_substr(linevalue,'\w{3}',1,2) w2
  ,regexp_substr(linevalue,'\w{3}',1,3) w3
from input_data where lineno >= 3;

-- for regex_substr, look at linevalue, start at character 1, get the 1st 3 letter word
--   start at character 1, get the 2nd 3 letter word, etc.
select
  lineno
  ,linevalue
  ,regexp_substr(linevalue,'\w{3}',1,1) w1
  ,regexp_substr(linevalue,'\w{3}',1,2) w2
  ,regexp_substr(linevalue,'\w{3}',1,3) w3
from input_data where lineno >= 3;

create or replace view nodes as
select
  lineno id
--  ,linevalue
  ,regexp_substr(linevalue,'\w{3}',1,1) node
  ,regexp_substr(linevalue,'\w{3}',1,2) next_node_l
  ,regexp_substr(linevalue,'\w{3}',1,3) next_node_r
from input_data where lineno >= 3;
select * from nodes;

-- extract the move instructions, but get more information
select
--  i.linevalue
--  , n.id
  n.id move_number
  , n.column_value direction
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue))) n
where lineno = 1;

create or replace view lr_instructions as
select
--  i.linevalue
--  , n.id
  n.id move_number
  , n.column_value direction
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue))) n
where lineno = 1;

select * from lr_instructions;
select * from nodes;

-- now what?
-- oh yeah, recurse!
select * from nodes where node = 'AAA';

select n.node
  , 1 move_number
  , i.direction direction
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = 1
/

with moves(node, move_number, direction) as (
  select n.node
    , 1 move_number
    , i.direction direction
  from nodes n, lr_instructions i
  where n.node = 'AAA' and i.move_number = 1

  union all

  select 'AAA',1,'1' from nodes where 1 = 0
)
select * from moves;

-- looks like I'll need the maximum of moves
select count(*) from lr_instructions;
create or replace view number_of_instructions as (
  select count(*) num from lr_instructions
);
select * from number_of_instructions;


select * from lr_instructions;
/* MOVE_NUMBER	DIRECTION
1	R
2	L */
select * from nodes;
/* ID	NODE	NEXT_NODE_L	NEXT_NODE_R
3	AAA	BBB	CCC
4	BBB	DDD	EEE
5	CCC	ZZZ	GGG
6	DDD	DDD	DDD
7	EEE	EEE	EEE
8	GGG	GGG	GGG
9	ZZZ	ZZZ	ZZZ */
select * from number_of_instructions;
/* NUM
2 */
