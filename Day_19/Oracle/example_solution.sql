-- Sample
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
  , substr(part_value,instr(part_value,'=')+1) value
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

create or replace view workflow_steps as
select s.wf_id, s.wf_name, s.wfr_order
  , substr(wf_condition,1,1) r_attr
  , substr(wf_condition,2,1) r_compare
  , substr(wf_condition,3) r_value
  , s.wf_destination
from workflow_sub1 s
;
select * from workflow_steps;
/*
WF_ID	WF_NAME	WFR_ORDER	R_ATTR	R_COMPARE	R_VALUE	WF_DESTINATION
1	px	1	a	<	2006	qkq
1	px	2	m	>	2090	A
1	px	3				rfg
2	pv	1	a	>	1716	R
*/
-----------------------------------
