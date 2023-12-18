create or replace synonym input_data for day13_example;

select * from input_data;

-- need to pivot.. there may be a better way but I know this one
select
  lineno y,
  linevalue x_line,
  sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
from input_data
/

with xline as (
  select
    lineno y,
    linevalue x_line,
    sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
  from input_data)
select * from xline
/

with xline as (
  select
    to_number(lineno) lineno,
    linevalue x_line,
    sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
  from input_data)
select * from xline
/

with xline as (
  select
    to_number(lineno) lineno,
    linevalue x_line,
    sum(nvl2(linevalue,0,1)) over (order by lineno rows between unbounded preceding and current row) mirror_id
  from input_data)
--select * from xline
select
  x.mirror_id
  , n.id x
  , row_number() over (partition by x.mirror_id, x.lineno order by x.lineno) y
  , n.column_value cell
from xline x
  ,lateral(select rownum id, column_value from table(string2rows(x.x_line))) n
where x.x_line is not null
order by x.mirror_id, x.lineno, n.id
/


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

/*

MIRROR_ID	Y	Y_LINE
0	1	#.##..#
0	2	..##...
0	3	##..###
0	4	#....#.
0	5	.#..#.#
0	6	.#..#.#
0	7	#....#.
0	8	##..###
0	9	..##...
1	1	##.##.#
1	2	...##..
1	3	..####.
1	4	..####.
1	5	#..##..
1	6	##....#
1	7	..####.
1	8	..####.
1	9	###..##

from this:
MIRROR_ID	X	X_LINE
0	1	#.##..##.
0	2	..#.##.#.
0	3	##......#
0	4	##......#
0	5	..#.##.#.
0	6	..##..##.
0	7	#.#.##.#.
1	1	
1	2	#...##..#
1	3	#....#..#
1	4	..##..###
1	5	#####.##.
1	6	#####.##.
1	7	..##..###
1	8	#....#..#
expected:
#.##..#
..##...
##..###
#....#.
.#..#.#
.#..#.#
#....#.
##..###
..##...

##.##.#
...##..
..####.
..####.
#..##..
##....#
..####.
..####.
###..##

looks right
*/


/*
In the first pattern, the reflection is across a vertical line between two columns; arrows on each of the two columns point at the line between the columns:

123456789
    ><
#.##..##.
..#.##.#.
##......#
##......#
..#.##.#.
..##..##.
#.#.##.#.
    ><
123456789
In this pattern, the line of reflection is the vertical line between columns 5 and 6. Because the vertical line is not perfectly in the middle of the pattern, part of the pattern (column 1) has nowhere to reflect onto and can be ignored; every other column has a reflected column within the pattern and must match exactly: column 2 matches column 9, column 3 matches 8, 4 matches 7, and 5 matches 6.
*/
--select * from xline where mirror_id=0 order by x;
select * from yline where mirror_id=0 order by y;
-- between 5 and 6
select y1.y, y1.y_line, y2.y, y2.y_line
from yline y1, yline y2
where y1.mirror_id=0
  and y2.mirror_id=0
  and y1.y_line = y2.y_line
  and y1.y != y2.y
order by y1.y, y2.y
;

/*
Y	Y_LINE	Y_1	Y_LINE_1
2	..##...	9	..##...
3	##..###	8	##..###
4	#....#.	7	#....#.
5	.#..#.#	6	.#..#.#
6	.#..#.#	5	.#..#.#
7	#....#.	4	#....#.
8	##..###	3	##..###
9	..##...	2	..##...
*/
-- a proper mirror starts at an edge
-- test on mirror_id 1, which reflects over xline
select count(*) from xline where mirror_id=1;
-- 7, so can start at 1 or 7
select x1.x x1, x1.x_line x1_line, x2.x x2, x2.x_line x2_line
from xline x1, xline x2
where x1.mirror_id=1
  and x2.mirror_id=1
  and x1.x_line = x2.x_line
  and x1.x != x2.x
order by x1.x, x2.x
;
/*
X1	X1_LINE	X2	X2_LINE
2	#....#..#	7	#....#..#
3	..##..###	6	..##..###
4	#####.##.	5	#####.##.
5	#####.##.	4	#####.##.
6	..##..###	3	..##..###
7	#....#..#	2	#....#..#

-- hmm, add x1+x2, that will be constant
*/
select x1.x x1, x1.x_line x1_line, x2.x x2, x2.x_line x2_line
  , x1.x + x2.x key
from xline x1, xline x2
where x1.mirror_id=1
  and x2.mirror_id=1
  and x1.x_line = x2.x_line
  and x1.x != x2.x
order by x1.x, x2.x
;

-- to simplify things, let's build a view that has the 4 orientation to look at the mirrors
select mirror_id, '1' orientation
  , row_number() over (partition by mirror_id order by x) the_row
  , x_line the_line
from xline union all
select mirror_id, '2'
  ,row_number() over (partition by mirror_id order by x desc) the_row
  , x_line the_line
from xline union all
select mirror_id, '3'
  , row_number() over (partition by mirror_id order by y) the_row
  , y_line the_line
from yline union all
select mirror_id, '4'
  , row_number() over (partition by mirror_id order by y desc) the_row
  , y_line the_line
from yline;


create or replace view all_orientations as
select mirror_id, '1' orientation
  , row_number() over (partition by mirror_id order by x) the_row
  , x_line the_line
from xline union all
select mirror_id, '2'
  ,row_number() over (partition by mirror_id order by x desc) the_row
  , x_line the_line
from xline union all
select mirror_id, '3'
  , row_number() over (partition by mirror_id order by y) the_row
  , y_line the_line
from yline union all
select mirror_id, '4'
  , row_number() over (partition by mirror_id order by y desc) the_row
  , y_line the_line
from yline;

select a1.mirror_id, a1.the_row, a1.the_line, a2.the_row, a2.the_line
  , a1.the_row + a2.the_row
from all_orientations a1, all_orientations a2
where 1=1
--  and a1.mirror_id = 0
  and a1.mirror_id = a2.mirror_id
--  and a1.orientation = 4
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;

create or replace view line_matches as
select a1.mirror_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1, a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key
from all_orientations a1, all_orientations a2
where 1=1
--  and a1.mirror_id = 0
  and a1.mirror_id = a2.mirror_id
--  and a1.orientation = 4
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;

select * from line_matches order by mirror_id,orientation, key, the_row1;
select * from line_matches
where the_row1 = 1;
/*
MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY
0	4	1	..##...	8	..##...	9
1	2	1	#....#..#	6	#....#..#	7
*/


--------------------------------------------------------------------------------------------
create or replace synonym input_data for day13_example;


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

-- orientation what line starts row1, T=>top down, B=>bottom up, L=>left, R=>right
create or replace view all_orientations as
select mirror_id, 'T' orientation
  , row_number() over (partition by mirror_id order by x) the_row
  , x_line the_line
from xline union all
select mirror_id, 'B'
  ,row_number() over (partition by mirror_id order by x desc) the_row
  , x_line the_line
from xline union all
select mirror_id, 'L'
  , row_number() over (partition by mirror_id order by y) the_row
  , y_line the_line
from yline union all
select mirror_id, 'R'
  , row_number() over (partition by mirror_id order by y desc) the_row
  , y_line the_line
from yline;
select * from all_orientations order by mirror_id, orientation, the_row;

create or replace view line_matches as
select a1.mirror_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1, a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key
from all_orientations a1, all_orientations a2
where 1=1
--  and a1.mirror_id = 0
  and a1.mirror_id = a2.mirror_id
--  and a1.orientation = 4
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;

select * from line_matches order by mirror_id,orientation, key, the_row1;
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease
from line_matches
where the_row1 = 1;

/* if orientation ..
  T => #lines = count(*) < crease (above the crease), horizontal so *100
  B => #lines = count(*) > crease (flipped...), horizontal so *100
  L => #lines = count(*) < crease, *1
  R -> #lines = count(*) > crease, *1
*/
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

select * from line_matches order by mirror_id,orientation, key, the_row1;
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease
from line_matches
where the_row1 = 1;

create or replace view a as
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from line_matches
where the_row1 = 1;
select sum(multiplier*num_lines) from a;
