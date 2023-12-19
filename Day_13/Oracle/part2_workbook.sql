create or replace synonym input_data for day13_example;

/* 
basically, for a mirror, flip 1 square
  check if that generates a valid reflection, different from the original reflection
  if yes, score it
  if no, reset and flip the next square...
so brute force it? Part1 wasn't too bad so maybe this won't be too bad
*/

create or replace view part1_solutions as
select mirror_id, orientation, key/2 crease
from b13
where the_count = the_max and the_row1 = the_max;


-- previous views
select * from numbered_mirrors;
select * from xline;
select * from xy;
select * from yline;
select * from all_orientations order by mirror_id, orientation, the_row;
select * from line_matches order by mirror_id,orientation, key, the_row1;
select * from a;

-- part1
select * from b13 where the_count = the_max and the_row1 = the_max;
select sum(multiplier*num_lines) from a13;

create or replace view xy as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy order by mirror_id, x, y;
select *
from xy xy1, xy xy2
where xy1.mirror_id = xy2.mirror_id
/


-- not working right
create or replace view smudged_xy as
select xy1.mirror_id
  , xy1.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy xy1, xy xy2
where xy1.mirror_id = xy2.mirror_id
  and xy1.cell_id != xy2.cell_id
--  and xy1.cell_id = xy2.cell_id
order by xy1.mirror_id, xy1.x,xy1.y
/
select * from smudged_xy
where mirror_id = 0
;

----- this should do it
create or replace view xy as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy order by mirror_id, x, y;

create or replace view smudged_xy as
select xy1.mirror_id
  , xy2.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy xy1, xy xy2
where xy1.mirror_id = xy2.mirror_id
--  and xy1.cell_id != xy2.cell_id
--  and xy1.cell_id = xy2.cell_id
/
select * from smudged_xy
where mirror_id = 0
order by mirror_id, smudge_id, x,y
;

-- so we have mirror_id and cell_id
create or replace view yline_s as
select
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y
/
select * from yline_s
order by mirror_id, smudge_id, y;

create or replace view xline_s as
select
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x
/
select * from xline_s
order by mirror_id, smudge_id, x;



create or replace view all_orientations as
select mirror_id, smudge_id, 'T' orientation
  , row_number() over (partition by mirror_id order by x) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id) tot
from xline_s union all
select mirror_id, smudge_id, 'B'
  ,row_number() over (partition by mirror_id order by x desc) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id) tot
from xline_s union all
select mirror_id, smudge_id, 'L'
  , row_number() over (partition by mirror_id order by y) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id) tot
from yline_s union all
select mirror_id, smudge_id, 'R'
  , row_number() over (partition by mirror_id order by y desc) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id) tot
from yline_s;
select * from all_orientations order by mirror_id, orientation, the_row;





-------------------------------------------------------------------------------------------
create or replace synonym input_data for day13_example;

select * from numbered_mirrors;
select * from xline;
select * from xy;
select * from yline;
select * from all_orientations order by mirror_id, orientation, the_row;
select * from line_matches order by mirror_id,orientation, key, the_row1;
select * from a;

-- part1
select * from b13
-- where the_count = the_max and the_row1 = the_max
;
select * from a13;

-- add cell_id
create or replace view xy_s as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy_s order by mirror_id, x, y;
select *
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
  and xy1.mirror_id = 0
--  and xy1.cell_id = xy2.cell_id
  and xy1.x=1
order by xy1.x, xy1.y
/

create or replace view smudged_xy as
select xy1.mirror_id
  , xy2.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
--  and xy1.cell_id != xy2.cell_id
--  and xy1.cell_id = xy2.cell_id
/
select * from smudged_xy
where mirror_id = 0
order by mirror_id, smudge_id, x,y
;

-- so we have mirror_id and cell_id
create or replace view yline_s as
select
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y
/
select * from yline_s
order by mirror_id, smudge_id, y;

create or replace view xline_s as
select
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x
/
select * from xline_s
order by mirror_id, smudge_id, x;


create or replace view all_orientations_s as
select mirror_id, smudge_id, 'T' orientation
  , row_number() over (partition by mirror_id,smudge_id order by x) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'B'
  ,row_number() over (partition by mirror_id,smudge_id order by x desc) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'L'
  , row_number() over (partition by mirror_id,smudge_id order by y) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s union all
select mirror_id, smudge_id, 'R'
  , row_number() over (partition by mirror_id,smudge_id order by y desc) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s;
select * from all_orientations_s order by mirror_id, smudge_id, orientation, the_row;


create or replace view line_matches_s as
select a1.mirror_id, a1.smudge_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1
  , a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key, a1.tot
from all_orientations_s a1, all_orientations_s a2
where 1=1
  and a1.mirror_id = a2.mirror_id
  and a1.smudge_id = a2.smudge_id
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;
select * from line_matches_s order by mirror_id,smudge_id, orientation, key, the_row1;

create or replace view b13_s as
select mirror_id, smudge_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id,smudge_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id,smudge_id, orientation, key) the_max
from line_matches_s
;
select * from b13_s
where mirror_id = 0 and orientation='T'
order by mirror_id, smudge_id, orientation, the_row1;

select * from b13_s
where the_count = the_max and the_row1 = the_max
order by mirror_id, smudge_id, orientation, the_row1;








------------------------------------------------------------------------------------------------
create or replace view xy_s as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy_s order by mirror_id, x, y;
select *
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
  and xy1.mirror_id = 0
--  and xy1.cell_id = xy2.cell_id
  and xy1.x=1
order by xy1.x, xy1.y
/
select count(*) from xy_s;

create or replace view xy_s as
with z as (
select /*+ materialize */
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null)
select * from z
/
select count(*) from xy_s;

create or replace view smudged_xy as
select xy1.mirror_id
  , xy2.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
--  and xy1.cell_id != xy2.cell_id
--  and xy1.cell_id = xy2.cell_id
/
select * from smudged_xy
where mirror_id = 0
order by mirror_id, smudge_id, x,y
;
select count(*) from smudged_xy;

-- so we have mirror_id and cell_id
create or replace view yline_s as
select
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y
/
select * from yline_s
order by mirror_id, smudge_id, y;
select count(*) from yline_s;

create or replace view yline_s as
with z as (
select /*+ materialize */
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y)
select * from z
/

create or replace view xline_s as
select
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x
/
select * from xline_s
order by mirror_id, smudge_id, x;
select count(*) from xline_s;

create or replace view xline_s as
with z as (
select /*+ materialized */
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x)
select * from z;
/


create or replace view all_orientations_s as
select mirror_id, smudge_id, 'T' orientation
  , row_number() over (partition by mirror_id,smudge_id order by x) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'B'
  ,row_number() over (partition by mirror_id,smudge_id order by x desc) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'L'
  , row_number() over (partition by mirror_id,smudge_id order by y) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s union all
select mirror_id, smudge_id, 'R'
  , row_number() over (partition by mirror_id,smudge_id order by y desc) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s;
select * from all_orientations_s order by mirror_id, smudge_id, orientation, the_row;
select count(*) from all_orientations_s;

create or replace view line_matches_s as
select a1.mirror_id, a1.smudge_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1
  , a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key, a1.tot
from all_orientations_s a1, all_orientations_s a2
where 1=1
  and a1.mirror_id = a2.mirror_id
  and a1.smudge_id = a2.smudge_id
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;
select * from line_matches_s order by mirror_id,smudge_id, orientation, key, the_row1;
select count(*) from line_matches_s;

create or replace view b13_s as
select mirror_id, smudge_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id,smudge_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id,smudge_id, orientation, key) the_max
from line_matches_s
;
select * from b13_s;
select count(*) from b13_s;
select * from b13_s
where mirror_id = 0 and orientation='T'
order by mirror_id, smudge_id, orientation, the_row1;

select * from b13_s
where the_count = the_max and the_row1 = the_max
order by mirror_id, smudge_id, orientation, the_row1;

create or replace view a13_s as
select mirror_id, smudge_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from b13_s
where the_count = the_max and the_row1 = the_max;
select * from a13_s;

select unique mirror_id, orientation, crease from a13_s
where (mirror_id, orientation, crease) not in (select mirror_id, orientation, crease from part1_solutions);

select sum(multiplier*num_lines) from a13_s;

create or replace view part1_solutions as
select mirror_id, orientation, key/2 crease
from b13
where the_count = the_max and the_row1 = the_max;
select * from part1_solutions;

select sum(multiplier*num_lines) from (
  select unique mirror_id, multiplier, num_lines from a13_s
  where (mirror_id, orientation, crease) not in (select mirror_id, orientation, crease from part1_solutions)
)
;


create or replace synonym input_data for day13_part1;




----------------------------------------------------------------------------------------------------------------------
create or replace view xy_s as
select
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
/
select * from xy_s order by mirror_id, x, y;
select *
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
  and xy1.mirror_id = 0
--  and xy1.cell_id = xy2.cell_id
  and xy1.x=1
order by xy1.x, xy1.y
/
select count(*) from xy_s;

create or replace view xy_s as
with z as (
select /*+ materialize */
  x.mirror_id
  , x.x
  , row_number() over (partition by x.mirror_id, x.x order by n.id) y
  , n.column_value cell
  , row_number() over (partition by x.mirror_id order by 1) cell_id
  , decode(n.column_value,'#','.','.','#') smudge
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null)
select * from z
/
select count(*) from xy_s;

create or replace view smudged_xy as
select xy1.mirror_id
  , xy2.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
--  and xy1.cell_id != xy2.cell_id
--  and xy1.cell_id = xy2.cell_id
/
select * from smudged_xy
where mirror_id = 0
order by mirror_id, smudge_id, x,y
;
select count(*) from smudged_xy;

-- so we have mirror_id and cell_id
create or replace view yline_s as
select
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y
/
select * from yline_s
order by mirror_id, smudge_id, y;
select count(*) from yline_s;

create or replace view yline_s as
with z as (
select /*+ materialize */
  mirror_id
  , smudge_id
  , y
  , listagg(smudge) within group (order by x) y_line
from smudged_xy
group by mirror_id, smudge_id, y)
select * from z
/

create or replace view xline_s as
select
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x
/
select * from xline_s
order by mirror_id, smudge_id, x;
select count(*) from xline_s;

create or replace view xline_s as
with z as (
select /*+ materialized */
  mirror_id
  , smudge_id
  , x
  , listagg(smudge) within group (order by y) x_line
from smudged_xy
group by mirror_id, smudge_id, x)
select * from z;
/


create or replace view all_orientations_s as
select mirror_id, smudge_id, 'T' orientation
  , row_number() over (partition by mirror_id,smudge_id order by x) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'B'
  ,row_number() over (partition by mirror_id,smudge_id order by x desc) the_row
  , x_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from xline_s union all
select mirror_id, smudge_id, 'L'
  , row_number() over (partition by mirror_id,smudge_id order by y) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s union all
select mirror_id, smudge_id, 'R'
  , row_number() over (partition by mirror_id,smudge_id order by y desc) the_row
  , y_line the_line
  , count(*) over (partition by mirror_id,smudge_id) tot
from yline_s;
select * from all_orientations_s order by mirror_id, smudge_id, orientation, the_row;
select count(*) from all_orientations_s;

create or replace view line_matches_s as
select a1.mirror_id, a1.smudge_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1
  , a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key, a1.tot
from all_orientations_s a1, all_orientations_s a2
where 1=1
  and a1.mirror_id = a2.mirror_id
  and a1.smudge_id = a2.smudge_id
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;
select * from line_matches_s order by mirror_id,smudge_id, orientation, key, the_row1;
select count(*) from line_matches_s;

create or replace view b13_s as
select mirror_id, smudge_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id,smudge_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id,smudge_id, orientation, key) the_max
from line_matches_s
;
select * from b13_s;
select count(*) from b13_s;
select * from b13_s
where mirror_id = 0 and orientation='T'
order by mirror_id, smudge_id, orientation, the_row1;

select * from b13_s
where the_count = the_max and the_row1 = the_max
order by mirror_id, smudge_id, orientation, the_row1;

create or replace view a13_s as
select mirror_id, smudge_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from b13_s
where the_count = the_max and the_row1 = the_max;
select * from a13_s;

select unique mirror_id, orientation, crease from a13_s
where (mirror_id, orientation, crease) not in (select mirror_id, orientation, crease from a13);

select sum(multiplier*num_lines) from a13_s;

create or replace synonym input_data for day13_part1;



select sum(multiplier*num_lines) from (
  select unique mirror_id, multiplier, num_lines from a13_s
  where (mirror_id, orientation, crease) not in (select mirror_id, orientation, crease from part1_solutions)
)
;
-- worked
