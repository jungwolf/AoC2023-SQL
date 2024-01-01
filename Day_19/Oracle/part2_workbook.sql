--Each of the four ratings (x, m, a, s) can have an integer value ranging from a minimum of 1 to a maximum of 4000. Of all possible distinct combinations of ratings, your job is to figure out which ones will be accepted.


create or replace synonym input_data for day19_example;


create or replace view workflows_and_parts as
select
  to_number(lineno) lineno,
  linevalue,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) group_id
from input_data
/
select * from workflows_and_parts;

create or replace view workflow_sub1 as
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

/*
wf_id	wf_name	wfr_order	r_attr	r_compare	r_value	wf_destination
-2	R	1		D		
-1	A	1		D		
1	px	1	a	<	2006	qkq
1	px	2	m	>	2090	A
1	px	3		D		rfg
2	pv	1	a	>	1716	R
...
*/





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
select * from a,parts_attrs p where wf_name in ('A') and a.part_id = p.part_id;
--19114


with a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination) as (
select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination
from workflow_steps
where wf_name = 'in'
)
select * from a;

select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination
from workflow_steps
where wf_name = 'in'
order by wf_name, wfr_order;

with a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, lvl) as (
  select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, 1
  from workflow_steps
  where wf_name = 'in'

  union all

  select w.wf_name, w.wfr_order, w.r_attr, w.r_compare, w.r_value, w.wf_destination, a.lvl+1
  from a, workflow_steps w
  where a.wf_destination = w.wf_name
    and w.wf_name not in ('A','R')

)
select * from a;


with a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, lvl, the_path) as (
  select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, 1, wf_name||'.'||wfr_order||'\'
  from workflow_steps
  where wf_name = 'in'

  union all

  select w.wf_name, w.wfr_order, w.r_attr, w.r_compare, w.r_value, w.wf_destination, a.lvl+1, a.the_path||w.wf_name||'.'||w.wfr_order||'\'
  from a, workflow_steps w
  where a.wf_destination = w.wf_name
    and w.wf_name not in ('A','R')

)
select * 
from a
where wf_destination = 'A'
order by the_path;
-- '
-- something odd with notepad++ quoting so added a single quote

-- let's assume we don't revisit a node
-- hmm, how about listing all the boundary values?
select * from workflows_and_parts;
select * from workflow_sub1;
select * from workflow_steps;

create or replace view critical_points as
with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
select r_attr, r_value+offset from workflow_steps, spread
where r_compare not in ('D')
order by 1, 2;
select * from critical_points;

create or replace view critical_points as
with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
select r_attr attr, r_value+offset value from workflow_steps, spread
where r_compare not in ('D')
order by 1, 2;
select * from critical_points;

with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
, critical_points as (
  select /*+ materialize */ r_attr attr, r_value+offset value from workflow_steps, spread
  where r_compare not in ('D')
)
select * 
from critical_points x
  , critical_points m
  , critical_points a
  , critical_points s
where x.attr='x'
  and m.attr='m'
  and a.attr='a'
  and s.attr='s'
;

-- too many
with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
, a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, lvl, the_path) as (
  select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, 1, wf_name||'.'||wfr_order||'/'
  from workflow_steps
  where wf_name = 'in'

  union all

  select w.wf_name, w.wfr_order, w.r_attr, w.r_compare, w.r_value, w.wf_destination, a.lvl+1, a.the_path||w.wf_name||'.'||w.wfr_order||'/'
  from a, workflow_steps w
  where a.wf_destination = w.wf_name
    and w.wf_name not in ('A','R')

)
select * 
from a
--where wf_destination = 'A'
order by the_path;

with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
, a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, lvl, the_path) as (
  select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, 1, wf_name||'.'||wfr_order||'/'
  from workflow_steps
  where wf_name = 'in'

  union all

  select w.wf_name, w.wfr_order, w.r_attr, w.r_compare, w.r_value, w.wf_destination, a.lvl+1, a.the_path||w.wf_name||'.'||w.wfr_order||'/'
  from a, workflow_steps w
  where a.wf_destination = w.wf_name
    and w.wf_name not in ('A','R')

)
select 
--  *
--  r_attr, r_value+offset 
--  unique r_attr, r_value+offset
  r_attr, count(*)
from a, spread
--where wf_destination = 'A'
where r_attr is not null
group by r_attr
--order by 1,2
/
/* count(*) 3456
 unique 3020
s	858
a	963
x	822
m	813
*/






with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
, a (wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, lvl, the_path) as (
  select wf_name, wfr_order, r_attr, r_compare, r_value, wf_destination, 1, wf_name||'.'||wfr_order||'/'
  from workflow_steps
  where wf_name = 'in'

  union all

  select w.wf_name, w.wfr_order, w.r_attr, w.r_compare, w.r_value, w.wf_destination, a.lvl+1, a.the_path||w.wf_name||'.'||w.wfr_order||'/'
  from a, workflow_steps w
  where a.wf_destination = w.wf_name
    and w.wf_name not in ('A','R')
    and w.r_attr is not null
)
, critical_values as (
  select 
    r_attr attr, r_value+offset value
  from a, spread
  where r_attr is not null
)
select count(*) 
from critical_values x
  , critical_values m
  , critical_values a
  , critical_values s
where x.attr='x'
  and m.attr='m'
  and a.attr='a'
  and s.attr='s'
/




with spread as (select -1 offset from dual union all select 1 from dual union all select 0 from dual)
, critical_values_x as (
  select /*+ materialize */
    unique r_attr attr, r_value+offset value
  from workflow_steps, spread
  where r_attr = 'x'
)
, critical_values_m as (
  select /*+ materialize */
    unique r_attr attr, r_value+offset value
  from workflow_steps, spread
  where r_attr = 'm'
)
, critical_values_a as (
  select /*+ materialize */
    unique r_attr attr, r_value+offset value
  from workflow_steps, spread
  where r_attr = 'a'
)
, critical_values_s as (
  select /*+ materialize */
    unique r_attr attr, r_value+offset value
  from workflow_steps, spread
  where r_attr = 's'
)
select count(*) from (
select unique *
from
   critical_values_x -- 739
,   critical_values_m -- 728
,   critical_values_a -- 806
--  critical_values_s -- 747
where 1=1
)
--order by 1,2
/

select * from workflows_and_parts;
select * from workflow_sub1;
select * from workflow_steps;
select * from workflow_steps where r_attr is not null;
select r_attr, count(*) from workflow_steps where r_attr is not null group by r_attr;

-- well, still looking at about a trillion values...

