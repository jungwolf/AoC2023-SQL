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
