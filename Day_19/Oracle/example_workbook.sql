-- scratchpad for creating the solution
create or replace synonym input_data for day19_example;

select * from input_data;


create or replace view workflows_and_parts as
select
  to_number(lineno) lineno,
  linevalue,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) group_id
from input_data
/
select * from workflows_and_parts
where linevalue is not null
;

-- parts
select *
from workflows_and_parts
where linevalue is not null
  and group_id = 1
;

create or replace view parts as
select p.lineno part_id, n.column_value part_value
from workflows_and_parts p
  ,lateral(select column_value from table(string2rows(
     replace(replace(p.linevalue,'{'),'}')
     , ','
   ))) n
where p.linevalue is not null
  and p.group_id = 1
;
select part_id, instr(part_value,'=')
  , substr(part_value,1,instr(part_value,'=')-1) attr
  , substr(part_value,instr(part_value,'=')+1) value
from parts;

create or replace view parts_attrs as
select part_id
  , substr(part_value,1,instr(part_value,'=')-1) attr
  , to_number(substr(part_value,instr(part_value,'=')+1)) value
from parts;
select * from parts_attrs;
/*
PART_ID	ATTR	VALUE
13	x	787
13	m	2655
13	a	1222
13	s	2876
14	x	1679
*/

-----------------------------------
-- workflows
create or replace view workflow_rules as
select lineno wf_id
--  , instr(linevalue,'{')
  , substr(linevalue,1,instr(linevalue,'{')-1) wf_name
  , replace(substr(linevalue,instr(linevalue,'{')+1),'}') wf_rule
from workflows_and_parts
where linevalue is not null
  and group_id = 0
;
select * from workflow_rules;
--WF_ID	WF_NAME	WF_RULE
--1	px	a<2006:qkq,m>2090:A,rfg
--2	pv	a>1716:R,A

-- parse workflow, but leave wf_condistion for the next view, just to keep thinks a little simpler
create or replace view workflow_temp1 as
select w.wf_id, w.wf_name
  , row_number() over (partition by w.wf_id order by rownum) wfr_order
--  , n.column_value wfr_attr
--  , instr(n.column_value,':')
  , substr(n.column_value,1,instr(n.column_value,':')-1) wf_condition
  , substr(n.column_value,instr(n.column_value,':')+1) wf_destination
--  , count(*) over (partition by w.wf_id) wfr_default_attr
from workflow_rules w
  ,lateral(select rownum, column_value from table(string2rows(w.wf_rule,','))) n
;
select * from workflow_sub1;
/*
WF_ID	WF_NAME	WFR_ORDER	WF_CONDITION	WF_DESTINATION
1	px	1	a<2006	qkq
1	px	2	m>2090	A
1	px	3		rfg
2	pv	1	a>1716	R
*/ 

-- add "compare" D, meaning it is the default and should be taken
create or replace view workflow_steps as
select s.wf_id, s.wf_name, s.wfr_order
  , substr(wf_condition,1,1) r_attr
  , nvl(substr(wf_condition,2,1),'D') r_compare
  , to_number(substr(wf_condition,3)) r_value
  , s.wf_destination
from workflow_sub1 s
;
select * from workflow_steps;
/*
WF_ID	WF_NAME	WFR_ORDER	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION
1	px	1	a	<	2006	qkq
1	px	2	m	>	2090	A
1	px	3		D		rfg
2	pv	1	a	>	1716	R
*/
-----------------------------------
-- parts don't start at 1, so just picking the first part manually
select * from parts_attrs where part_id = 13;
/*
PART_ID	ATTR	VALUE
13	x	787
13	m	2655
13	a	1222
13	s	2876
*/
select * from workflow_steps where wf_name = 'in';
/*
WF_ID	WF_NAME	WFR_ORDER	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION
8	in	1	s	<	1351	px
8	in	2				qqz
*/


-- this will be the anchor of the recursive query
select unique p.part_id, 'in' wf_name
from parts_attrs p
where p.part_id = 13
/
-- so this is the dynamic...
with old_wf as (select unique p.part_id, 'in' wf_name from parts_attrs p where p.part_id = 13)
select o.part_id, o.wf_name
from old_wf o
  , workflow_steps s
  , parts_attrs p
where o.part_id = p.part_id
  and o.wf_name = s.wf_name;

-- trying out case to handle the <>= part
with old_wf as (select unique p.part_id, 'in' wf_name, 2 wfr_order from parts_attrs p where p.part_id = 13)
select o.*, s.*, p.*
  , case s.r_compare when '<' then nvl((select 1 from dual where p.value < s.r_value),0)
      when '=' then nvl((select 1 from dual where p.value = s.r_value),0)
      when '>' then nvl((select 1 from dual where p.value > s.r_value),0)
      when 'D' then 1
      else 1/0
    end expr
from old_wf o
  , workflow_steps s
  , parts_attrs p
where o.wf_name = s.wf_name
  and o.wfr_order = s.wfr_order
  and s.r_attr = p.attr (+)
  and o.part_id = p.part_id (+)
order by s.wfr_order;
/*
part_id 13 => {x=787,m=2655,a=1222,s=2876}
move 'in' => in{s<1351:px,qqz}
so should result in qqz

PART_ID	WF_NAME	WFR_ORDER	WF_ID	WF_NAME_1	WFR_ORDER_1	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION	PART_ID_1	ATTR	VALUE	EXPR
13	in	1	8	in	1	s	<	1351	px	13	s	2876	0

PART_ID	WF_NAME	WFR_ORDER	WF_ID	WF_NAME_1	WFR_ORDER_1	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION	PART_ID_1	ATTR	VALUE	EXPR
13	in	2	8	in	2		D		qqz				1
*/

-- it keeps returning result as '>' for 13 and 14
with old_wf as (select unique p.part_id, 'in' wf_name, 1 wfr_order from parts_attrs p where p.part_id = 13)
select --o.*, s.*, p.*
  o.part_id, o.wf_name, o.wfr_order, s.r_attr, s.r_compare, s.r_value, p.value, s.wf_destination wf_d
  , case s.r_compare
      when '<' then nvl((select 1 from dual where p.value < s.r_value),0)
      when '=' then nvl((select 2 from dual where p.value = s.r_value),0)
      when '>' then nvl((select 3 from dual where p.value > s.r_value),0)
      when 'D' then 4
      else 1/0
    end expr
  , nvl((select 1 from dual where p.value < s.r_value),0) "<"
  , nvl((select 1 from dual where p.value = s.r_value),0) "="
  , nvl((select 1 from dual where p.value > s.r_value),0) ">"
  , p.value, s.r_value
  , (select p.value-s.r_value from dual)
from old_wf o
  , workflow_steps s
  , parts_attrs p
where o.wf_name = s.wf_name
  and o.wfr_order = s.wfr_order
  and s.r_attr = p.attr (+)
  and o.part_id = p.part_id (+)
order by s.wfr_order;
/*
part_id 13 => {x=787,m=2655,a=1222,s=2876}
move 'in' => in{s<1351:px,qqz}
so should result in qqz
*/
--PART_ID	WF_NAME	WFR_ORDER	WF_ID	WF_NAME_1	WFR_ORDER_1	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION	PART_ID_1	ATTR	VALUE	EXPR
--13	in	1	s	<	1351	2876	px	0	0	0	1	2876	1351
--14	in	1	s	<	1351	496	px	0	0	0	1	496	1351

-- okay, the r_value and value columns were varchar2 instead of number, fixed those views, works

with old_wf as (select unique p.part_id, 'in' wf_name, 1 wfr_order from parts_attrs p where p.part_id in (13,14))
select --o.*, s.*, p.*
  o.part_id, o.wf_name, o.wfr_order, s.r_attr, s.r_compare, s.r_value, p.value, s.wf_destination wf_d
  , case s.r_compare
      when '<' then nvl((select 1 from dual where p.value < s.r_value),0)
      when '=' then nvl((select 2 from dual where p.value = s.r_value),0)
      when '>' then nvl((select 3 from dual where p.value > s.r_value),0)
      when 'D' then 4
      else 1/0
    end expr
  , nvl((select 1 from dual where p.value < s.r_value),0) "<"
  , nvl((select 1 from dual where p.value = s.r_value),0) "="
  , nvl((select 1 from dual where p.value > s.r_value),0) ">"
  , p.value, s.r_value
  , (select p.value-s.r_value from dual)
from old_wf o
  , workflow_steps s
  , parts_attrs p
where o.wf_name = s.wf_name
  and o.wfr_order = s.wfr_order
  and s.r_attr = p.attr (+)
  and o.part_id = p.part_id (+)
order by s.wfr_order;

-- okay, let's pare it down...
with old_wf as (select unique p.part_id, 'in' wf_name, 1 wfr_order from parts_attrs p where p.part_id in (13,14))
select --o.*, s.*, p.*
  o.part_id, o.wf_name, o.wfr_order, s.r_attr, s.r_compare, s.r_value, p.value, s.wf_destination wf_d
  , case s.r_compare
      when '<' then nvl((select s.wf_destination from dual where p.value < s.r_value),0)
      when '=' then nvl((select s.wf_destination from dual where p.value = s.r_value),0)
      when '>' then nvl((select s.wf_destination from dual where p.value > s.r_value),0)
      when 'D' then s.wf_destination
      else 1/0
    end expr
from old_wf o
  , workflow_steps s
  , parts_attrs p
where o.wf_name = s.wf_name
  and o.wfr_order = s.wfr_order
  and s.r_attr = p.attr (+)
  and o.part_id = p.part_id (+)
order by s.wfr_order;


-- starting recursive...
with a (part_id, wf_name, wfr_order, r_attr, r_compare, r_value, value, wf_d, expr) as (
  select p.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, p.value, wf.wf_destination, 0
  from parts_attrs p, workflow_steps wf
  where p.part_id in (13)
    and wf.wf_name = 'in'
    and wf.wfr_order = 1
    and wf.r_attr = p.attr

  union all

  select p.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, p.value, wf.wf_destination, 1
  from parts_attrs p, workflow_steps wf, a
  where p.part_id in (13)
    and wf.wf_name = 'in'
    and wf.wfr_order = 1
    and a.expr = 0
)
select * from a;


with a (part_id, wf_name, wfr_order, r_attr, r_compare, r_value, value, wf_d, expr, lvl) as (
  select p.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, p.value, wf.wf_destination
  , case wf.r_compare
      when '<' then nvl((select wf.wf_destination from dual where p.value < wf.r_value),'-')
      when '=' then nvl((select wf.wf_destination from dual where p.value = wf.r_value),'-')
      when '>' then nvl((select wf.wf_destination from dual where p.value > wf.r_value),'-')
      when 'D' then wf.wf_destination
    end expr
  , 0
  from parts_attrs p, workflow_steps wf
  where p.part_id in (13)
    and wf.wf_name = 'in'
    and wf.wfr_order = 1
    and wf.r_attr = p.attr

  union all

  select p.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, p.value, wf.wf_destination
  , case wf.r_compare
      when '<' then nvl((select wf.wf_destination from dual where p.value < wf.r_value),'-')
      when '=' then nvl((select wf.wf_destination from dual where p.value = wf.r_value),'-')
      when '>' then nvl((select wf.wf_destination from dual where p.value > wf.r_value),'-')
      when 'D' then wf.wf_destination
    end expr
    , lvl+1
  from parts_attrs p, workflow_steps wf, a
  where p.part_id in (13)
    and wf.wf_name = 'in'
    and wf.wfr_order = 1
    and a.lvl < 2
)
select * from a;

