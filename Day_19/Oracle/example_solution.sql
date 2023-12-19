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
         substr(translate('!'||p.linevalue
                          , '!{}'
                          , '!')
                ,2)
           , ','))) n
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

