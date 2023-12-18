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

