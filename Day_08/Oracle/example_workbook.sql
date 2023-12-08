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

-- so let's say I'm at node AAA, move 1, direction R
-- how do I find the next node?
select *
from nodes n, lr_instructions lr, number_of_instructions i
where n.node = 'AAA'
/

select *
from nodes n, lr_instructions lr, number_of_instructions i
where n.node = 'AAA'
  and 1 = lr.move_number
/

-- need a more complex example
create or replace synonym input_data for day08_example2;
select * from input_data;
select * from lr_instructions;
-- no rows, what?
select * from input_data where lineno = 1;
-- ug, problem with the input

-- okay, fixed


select * from nodes;
select * from number_of_instructions;
-- so let's say I'm at move 3 for example2
-- (AAA,1,L) = BBB
-- (BBB,2,L) = AAA
-- (AAA,3,R) = BBB
-- how do I find the next node?
-- should be (BBB,4,L) = AAA
-- should be (AAA,5,L) = BBB
-- should be (BBB,6,R) = ZZZ
select mod(3-1,i.num) from number_of_instructions i;

select mod(3-1,i.num) from number_of_instructions i;
-- 2
select lr.move_number, lr.direction
  , mod(move_number,3) mod3
  , decode(mod(move_number,3),0,3,mod(move_number,3)) mod3_0
from lr_instructions lr;
/* MOVE_NUMBER	DIRECTION	MOD3	MOD3_0
1	L	1	1
2	L	2	2
3	R	0	3 */

select *
from nodes n, lr_instructions lr, number_of_instructions i
where n.node = 'BBB'
  and mod(3-1,i.num) = lr.move_number
/
/* remember, mod is (0 to max-1)
ID	NODE	NEXT_NODE_L	NEXT_NODE_R	MOVE_NUMBER	DIRECTION	NUM
4	BBB	AAA	ZZZ	2	L	3
n.ID	n.NODE	n.NEXT_NODE_L	n.NEXT_NODE_R	lr.MOVE_NUMBER	lr.DIRECTION	i.NUM
*/

select *
from nodes n, lr_instructions lr, number_of_instructions i
where n.node = 'BBB'
--  and mod(3-1,i.num) = lr.move_number
/
/* ID	NODE	NEXT_NODE_L	NEXT_NODE_R	MOVE_NUMBER	DIRECTION	NUM
4	BBB	AAA	ZZZ	1	L	3
4	BBB	AAA	ZZZ	2	L	3
4	BBB	AAA	ZZZ	3	R	3 */

with x as (select level from dual connect by level <= 10)
select * from x;
-- yep 1-10

with x as (select level the_level from dual connect by level <= 5)
select x.the_level
  , mod(x.the_level,i.num) mod_normal
  ,decode(mod(x.the_level,i.num),0,i.num,mod(x.the_level,i.num)) mod_decode
from x, number_of_instructions i;
/* THE_LEVEL	MOD_NORMAL	MOD_DECODE
1	1	1
2	2	2
3	0	3
4	1	1
5	2	2 */
--so, move 3 will really be move 0.. 1,2,0


select num from number_of_instructions;
/* NUM
3 */
select move_number, direction from lr_instructions;
/* MOVE_NUMBER	DIRECTION
1	L
2	L
3	R */
select node, next_node_l, next_node_r from nodes;
/* NODE	NEXT_NODE_L	NEXT_NODE_R
AAA	BBB	BBB
BBB	AAA	ZZZ
ZZZ	ZZZ	ZZZ */

with moves(node, move_number, direction) as (
  select n.node
    , 1 move_number
    , i.direction direction
  from nodes n, lr_instructions i
  where n.node = 'AAA' and i.move_number = 1

  union all

  select decode(m.direction,'L',n.NEXT_NODE_L,'R',n.NEXT_NODE_L), m.move_number+1, lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where m.node = n.node
    and lr.move_number-1 = mod(m.move_number,i.num)
    and m.move_number < 10
)
select * from moves;

with moves(
    node, next_node_l, next_node_r
    , move_number, direction
  ) as (
  select n.node, n.next_node_l, n.next_node_r
    , i.move_number, i.direction direction
  from nodes n, lr_instructions i
  where n.node = 'AAA' and i.move_number = 1

  union all

  select decode(m.direction,'L',n.NEXT_NODE_L,'R',n.NEXT_NODE_L), m.move_number+1, lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where m.node = n.node
    and lr.move_number-1 = mod(m.move_number,i.num)
    and m.move_number < 10
)
select * from moves;


select n.node, n.next_node_l, n.next_node_r
  , i.move_number, i.direction direction
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = 1
/
/* NODE	NEXT_NODE_L	NEXT_NODE_R	MOVE_NUMBER	DIRECTION
AAA	BBB	BBB	1	L 

so next should be
-- (BBB,2,L) = AAA
NODE	NEXT_NODE_L	NEXT_NODE_R	MOVE_NUMBER	DIRECTION
BBB	AAA	ZZZ	2	L
*/
select n.node, n.next_node_l, n.next_node_r
  , i.move_number, i.direction direction
from nodes n, lr_instructions i
where n.node = 'BBB' and i.move_number = 2
/
--BBB	AAA	ZZZ	2	L

-- should be
-- AAA	BBB	BBB	3	R
select n.node, n.next_node_l, n.next_node_r
  , i.move_number, i.direction direction
from nodes n, lr_instructions i
where n.node = 'BBB' and i.move_number = 2
/

select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'BBB' and i.move_number = 2
/
/* NEXT_NODE	I.MOVE_NUMBER+1
AAA	3 */

select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = 3;
--BBB	4
select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = 4;
-- no records, because move number is 4 and should be mod 3 => 1
select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
  , mod(1,3)
  , mod(2,3)
  , mod(3,3)
  , mod(4,3)
  , mod(5,3)
  , mod(6,3)
  , mod(1,3)+1
  , mod(2,3)+1
  , mod(3,3)+1
  , mod(4,3)+1
  , mod(5,3)+1
  , mod(6,3)+1
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = mod(4,3);
-- nope, that's just 2,3,1 when I need 1,2,3
select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'BBB' and i.move_number = decode(mod(4,3),0,3,mod(4,3));

select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'AAA' and i.move_number = decode(mod(5,3),0,3,mod(5,3));

select
  decode(i.direction,'L',next_node_l,'R',next_node_r) next_node
  , i.move_number + 1
from nodes n, lr_instructions i
where n.node = 'BBB' and i.move_number = decode(mod(6,3),0,3,mod(6,3));

-- this is a hack
create or replace view lr_instructions as
select
  n.id move_number
  , n.id-1 mod_move
  , n.column_value direction
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue))) n
where lineno = 1;
select * from lr_instructions;



with moves(
    node, next_node_l, next_node_r
    , move_number, direction
  ) as (
  select n.node, n.next_node_l, n.next_node_r
    , i.move_number, i.direction direction
  from nodes n, lr_instructions i
  where n.node = 'AAA' and i.move_number = 1

  union all

  select decode(m.direction,'L',n.NEXT_NODE_L,'R',n.NEXT_NODE_L), m.move_number+1, lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where m.node = n.node
    and lr.mod_move = mod(m.move_number,i.num)
    and m.move_number < 10
)
select * from moves;



with moves(
    node, next_node_l, next_node_r
    , move_number
--    , mod_move
    , direction
  ) as (
  select n.node, n.next_node_l, n.next_node_r
    , i.move_number
--    , i.mod_move
    , i.direction direction
  from nodes n, lr_instructions i
  where n.node = 'AAA' and i.move_number = 1

  union all

  select
    decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_L)
    , n.next_node_l, n.next_node_r
    , m.move_number+1
--    ,mod(m.mod_move+1,i.num)
    , lr.direction
  from moves m, nodes n, lr_instructions lr, number_of_instructions i
  where 1=1
    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_L) = n.node
    and lr.move_number = decode(mod(m.move_number+1,i.num),0,i.num,mod(m.move_number+1,i.num))
--    and n.node != 'ZZZ'
    and m.move_number < 10
)
select * from moves;

select decode(mod(1,i.num),0,i.num,mod(1,i.num)) from number_of_instructions i;
select decode(mod(2,i.num),0,i.num,mod(2,i.num)) from number_of_instructions i;
select decode(mod(3,i.num),0,i.num,mod(3,i.num)) from number_of_instructions i;
select decode(mod(4,i.num),0,i.num,mod(4,i.num)) from number_of_instructions i;

with x as (move, mod_move) as (
  select 1, 0
  from dual
  
  union all
  
  select x.move+1, mod(x.move+1,i.num)
  from lr_instructions lr, number_of_instructions i
  where move < 10
)
select * from x;


-------------------------------------------------------
with move as (select 1 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'AAA'
  and lr.mod_move = mod(move.m,i.num)
/
--AAA	BBB	BBB	1	1	L

with move as (select 2 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'BBB'
  and lr.mod_move = mod(move.m,i.num)
/

with move as (select 3 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'AAA'
  and lr.mod_move = mod(move.m,i.num)
/

with move as (select 4 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'BBB'
  and lr.mod_move = mod(move.m,i.num)
/

with move as (select 5 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'AAA'
  and lr.mod_move = mod(move.m,i.num)
/

with move as (select 6 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'BBB'
  and lr.mod_move = mod(move.m,i.num)
/

with move as (select 7 m from dual)
select n.node, n.next_node_l, n.next_node_r
  , move.m
  , lr.mod_move
  , lr.direction direction
from nodes n, lr_instructions lr, number_of_instructions i, move
where n.node = 'ZZZ'
  and lr.mod_move = mod(move.m,i.num)
/
--- seems like it works


















--and a bug...
--    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_L) = n.node
-- R should point to R...
--    and decode(m.direction,'L',m.NEXT_NODE_L,'R',m.NEXT_NODE_R) = n.node

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
--    and n.node != 'ZZZ'
    and m.move_number < 10
)
select * from moves;

-- have a problem with lr_instructions using number_of_instructions
create or replace view number_of_instructions as
select len(linevalue) num
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


------- that seems to do it
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
    and m.move_number < 10
)
--select * from moves;
select count(*) from moves;