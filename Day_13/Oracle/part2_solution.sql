create or replace synonym input_data for day13_part1;

-- check the bottom notes for information on materialized, it doesn't change the logic

-- use a running sum of empty lines to identify mirror groups.
create or replace view numbered_mirrors as
select
  to_number(lineno) lineno,
  linevalue,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
from input_data
/
select * from numbered_mirrors;

-- remove blank lines, then number the lines in a mirror_id starting at 1 (see order by lineno)
create or replace view xline as
select
  mirror_id
  , row_number() over (partition by mirror_id order by lineno) x
  , linevalue x_line
from numbered_mirrors
where linevalue is not null
/

-- *_s views stand for smudge, to distinguish from the part1 views
-- we'll need part1 to remove its solutions

-- break out the individual mirror pieces with (x,y) positions
-- add smudge, the cell value if it is smudged
-- also added a unique cell_id for joining so not matching (x,y) all the time
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
-- i don't think i need the not null clause, check it later

/*
generate all the possible smudged mirrors
for each mirrorid, create new mirrors by replacing one piece with a smudged piece
how does that work? keep in mind each mirror has cellid 1..max(pieces), length*width
this is a Cartesian join for each mirrorid. for each cellid, we join to 1..max(cellid) copies.
when left cellid = right cellid, replace the regular cell value with the smudge value
now, each mirrorid is a group of mirrors, and smudgeid is a particular smudged version
*/
create or replace view smudged_xy as
select xy1.mirror_id
  , xy2.cell_id smudge_id
  , xy1.x
  , xy1.y
  , xy1.cell
  , decode(xy1.cell_id, xy2.cell_id, xy1.smudge, xy1.cell) smudge
from xy_s xy1, xy_s xy2
where xy1.mirror_id = xy2.mirror_id
/

-- create all the smudged mirrors in the y direction
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

-- create all the smudged mirrors in the x direction
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

-- look at the smudged mirrors in all directions, starting at top, bottom, left, right
-- orientation shows which direction a row uses
-- the_row is row number in that direction
-- tot is total number of rows in that direction, useful later
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

-- for each smudged mirror, in each orientation, find all the rows that are the same
-- don't include the row matched to itself
-- key, when we're looking at a real mirror, is used to find the reflection line
--   basically, all rows 1,2,3..maxmatch + maxmatch..3,2,1 have the same key value
--   call them a key group
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

-- within a key group, get the number of members and the max row number in the group
-- so? if and only if, a key group includes row 1, the number of rows and the max row number will be the same
--   i'm pretty sure i have the proof in a note
-- for that max row, we've given it all the information needed for the solution
create or replace view b13_s as
select mirror_id, smudge_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id,smudge_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id,smudge_id, orientation, key) the_max
from line_matches_s
;

/* I trust the puzzle writers that there are one and only one new solutions for each mirror
  for each mirrorid, there is one smudge mirror, in one orientation, with a solution
based on the above view, the_count=the_max gives the winning keygroup
  and the_max row has the necessary information
key/2 gives the crease locaion, always between two rows so #.5
orientation tells me how to find the number of row above or right of the crease
  also tells me if it is *1 or *100 for the answer
*/

create or replace view a13_s as
select mirror_id, smudge_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from b13_s
where the_count = the_max and the_row1 = the_max;
select * from a13_s;

-- the original part1 solution for a mirror might still be valid, so remove those
-- i think that clause removed the duplicates so probably don't need the in-line view
-- in any case, do the sum to get the answer
select sum(multiplier*num_lines) from (
  select unique mirror_id, multiplier, num_lines from a13_s
  where (mirror_id, orientation, crease) not in (select mirror_id, orientation, crease from part1_solutions)
)
;
-- worked
/*
sql is a declaritive language, and the oracle sql engine includes an optimisation part to find the best way to generate the answer, called a plan
in this case, view layered on view with heavy transformations, the oracle optimizer wasn't able to come up with a performant plan.
a view can be "materialized", basically cached, meaning the plan creates temporary lookup table once it has the rows from the view.
i gave it hints on what to materialize, so it wouldn't keep doing expensive parsing or computations.
there is some judgement, you don't want to materialize millions of rows.
initial parsing and row creation from a string is expensive if done millions of times, so materializing xy_s is an easy win
smudging is pretty expensive, so caching the smudged xline and yline helps.
*/

