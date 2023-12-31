create or replace synonym input_data for day13_part1;

-- example solution wasn't robust in catching mirrors

-- find the number of rows and the maximum row number within a key group
create or replace view b13 as
select mirror_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id, orientation, key) the_max
from line_matches
;
-- the mirrored lines must start with line 1 and have contiguous lines
-- when starting with row 1, the number of rows in a key will equal the maximum row in that key
select * from b13 where the_count = the_max and the_row1 = the_max;

-- key/2 is "row number" for the reflection. The number of rows above or to the left depends on the orientation
create or replace view a13 as
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from b13
where the_count = the_max and the_row1 = the_max;
-- answer
select sum(multiplier*num_lines) from a13;




















-- Sample
--create or replace synonym input_data for day??_part1;

create or replace synonym input_data for day13_part1;

create or replace view numbered_mirrors as
select
  to_number(lineno) lineno,
  linevalue,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
from input_data
/
select * from numbered_mirrors;

create or replace view xline as
select
  mirror_id
  , row_number() over (partition by mirror_id order by lineno) x
  , linevalue x_line
from numbered_mirrors
where linevalue is not null
/
select * from xline;

create or replace view xy as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy order by mirror_id, x, y
/

create or replace view yline as
select
  mirror_id
  , y
  , listagg(cell) within group (order by x) y_line
from xy
group by mirror_id, y
/
select * from yline
order by mirror_id, y;

create or replace view all_orientations as
select mirror_id, 'T' orientation
  , row_number() over (partition by mirror_id order by x) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id) tot
from xline union all
select mirror_id, 'B'
  ,row_number() over (partition by mirror_id order by x desc) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id) tot
from xline union all
select mirror_id, 'L'
  , row_number() over (partition by mirror_id order by y) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id) tot
from yline union all
select mirror_id, 'R'
  , row_number() over (partition by mirror_id order by y desc) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id) tot
from yline;
select * from all_orientations order by mirror_id, orientation, the_row;

create or replace view line_matches as
select a1.mirror_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1, a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key, a1.tot
from all_orientations a1, all_orientations a2
where 1=1
--  and a1.mirror_id = 0
  and a1.mirror_id = a2.mirror_id
--  and a1.orientation = 4
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;

