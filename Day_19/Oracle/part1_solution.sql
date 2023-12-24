-- Sample
create or replace synonym input_data for day19_part1;


-- divide input into two groups using count blank lines trick
create or replace view workflows_and_parts as
select
  to_number(lineno) lineno,
  linevalue,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) group_id
from input_data
/

/*
parts are the second input group, but started with them for some reason
  not null to remove the blank line from group 1
replace(string1,findstring[,replacestring]) -- replace a substring with another (default '')
  removing curly braces, not needed since just splitting the line on ','
*/
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
-- left with x=16 s=87 etc lines
-- split on = to give attributes and values
-- assume attr is single character
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

-- split the into the workflow name and rulw.
create or replace view workflow_rules as
select lineno wf_id
  , substr(linevalue,1,instr(linevalue,'{')-1) wf_name
  , replace(substr(linevalue,instr(linevalue,'{')+1),'}') wf_rule
from workflows_and_parts
where linevalue is not null
  and group_id = 0
-- would be nice if A and R were terminal workflows, instead of just null rows
union all select -1,'A',null from dual
union all select -2,'R',null from dual
;
select * from workflow_rules;
--WF_NAME	WF_RULE
--px	a<2006:qkq,m>2090:A,rfg
--pv	a>1716:R,A

-- parse workflows
--   but leave wf_condistion for the next view, just to keep thinks a little simpler
-- using row_number() to start each workflow with step 1
-- last default entry works due to the lack of a :
create or replace view workflow_temp1 as
select w.wf_id, w.wf_name
  , row_number() over (partition by w.wf_id order by rownum) wfr_order
  , substr(n.column_value,1,instr(n.column_value,':')-1) wf_condition
  , substr(n.column_value,instr(n.column_value,':')+1) wf_destination
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

-- sql doesn't have a compute string function, so '1+3' is surprisingly hard to work with
-- so separating out the attribute, comparison, and constant into columns
-- add "compare" D, meaning it is the default and should be taken whenever encountered
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




with a (part_id, wf_name, wfr_order, r_attr, r_compare, r_value, value, wf_d, expr, lvl) as (
  select p.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, p.value, wf.wf_destination
  , case wf.r_compare
      when '<' then nvl((select wf.wf_destination from dual where p.value < wf.r_value),wf.wf_name)
      when '=' then nvl((select wf.wf_destination from dual where p.value = wf.r_value),wf.wf_name)
      when '>' then nvl((select wf.wf_destination from dual where p.value > wf.r_value),wf.wf_name)
      when 'D' then wf.wf_destination
    end expr
  , 0
  from parts_attrs p, workflow_steps wf
  where 1=1
--    and p.part_id in (14,13)
    and wf.wf_name = 'in'
    and wf.wfr_order = 1
    and wf.r_attr = p.attr

  union all

  select a.part_id, wf.wf_name, wf.wfr_order, wf.r_attr, wf.r_compare, wf.r_value, a.value, wf.wf_destination
  , case wf.r_compare
      when '<' then nvl((select wf.wf_destination from dual where p.value < wf.r_value),wf.wf_name)
      when '=' then nvl((select wf.wf_destination from dual where p.value = wf.r_value),wf.wf_name)
      when '>' then nvl((select wf.wf_destination from dual where p.value > wf.r_value),wf.wf_name)
      when 'D' then wf.wf_destination
    end expr
    , lvl+1
  from parts_attrs p, workflow_steps wf, a
  where a.part_id = p.part_id (+)
    and wf.wf_name = a.expr
-- if on a new destination, restart order
    and wf.wfr_order = decode(a.expr,a.wf_name,a.wfr_order+1,1)
    and wf.r_attr = p. attr (+)
    and a.lvl < 10
)
select sum(p.value) from a,parts_attrs p where wf_name in ('A') and a.part_id = p.part_id;
--19114
