create or replace synonym input_data for day19_part1;

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
/*select * from a
where wfr_order = 1
order by part_id, lvl, wfr_order;
*/
/*select part_id, listagg(wf_name,' -> ') within group (order by lvl)
from a
group by part_id;*/
/*select part_id, wf_name
from a
where wf_name in ('A','R');*/
--select a.part_id, p.attr, p.value from a,parts_attrs p where wf_name in ('A','R') and a.part_id = p.part_id;
select sum(p.value) from a,parts_attrs p where wf_name in ('A') and a.part_id = p.part_id;

-- too low
---------------------------------
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


-- parse workflow, but leave wf_condistion for the next view, just to keep thinks a little simpler
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

create or replace view workflow_rules as
select lineno wf_id
--  , instr(linevalue,'{')
  , substr(linevalue,1,instr(linevalue,'{')-1) wf_name
  , replace(substr(linevalue,instr(linevalue,'{')+1),'}') wf_rule
from workflows_and_parts
where linevalue is not null
  and group_id = 0
union all select -1,'A',null from dual
union all select -2,'R',null from dual
;
select * from workflow_rules;

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


create or replace view workflow_steps as
select s.wf_id, s.wf_name, s.wfr_order
  , substr(wf_condition,1,1) r_attr
  , nvl(substr(wf_condition,2,1),'D') r_compare
  , to_number(substr(wf_condition,3)) r_value
  , s.wf_destination
from workflow_sub1 s
;
select * from workflow_steps;

-- ah, accidentially let in the lvl safety switch
-- removed that and got the correct answer
