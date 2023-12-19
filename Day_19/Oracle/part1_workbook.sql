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