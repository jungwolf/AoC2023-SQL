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

select * from line_matches order by mirror_id,orientation, key, the_row1;
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease
from line_matches
where the_row1 = 1
order by mirror_id, orientation, the_row1;

create or replace view a as
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from line_matches
where the_row1 = 1;
select sum(multiplier*num_lines) from a;




select mirror_id, orientation, the_row1, the_row2, key, key/2 crease
from line_matches
where the_row1 = 1
order by mirror_id, orientation, the_row1;
---
/*
MIRROR_ID	ORIENTATION	THE_ROW1	THE_ROW2	KEY	CREASE
0	B	1	8	9	4.5
0	T	1	4	5	2.5
*/
-- yep, they didn't make it easy. mirror_id 0, B/T so use xline
select * from xline where mirror_id = 0;
select * from line_matches 
where mirror_id = 0
  and orientation='T'
order by mirror_id,orientation, key, the_row1;
/*
MIRROR_ID	X	X_LINE	NUM_LINES
0	1	...##.#	15
0	2	.##.###	15
0	3	.##.###	15
0	4	...##.#	15
0	5	#...###	15
0	6	.#..##.	15
0	7	##.##.#	15
0	8	...####	15
0	9	#.#.###	15
0	10	#....#.	15
0	11	..#.##.	15
0	12	..#.##.	15
0	13	#....#.	15
0	14	#.#.#.#	15
0	15	...####	15


MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT
0	T	1	...##.#	4	...##.#	5	15
0	T	2	.##.###	3	.##.###	5	15
0	T	3	.##.###	2	.##.###	5	15
0	T	4	...##.#	1	...##.#	5	15
0	T	8	...####	15	...####	23	15
0	T	10	#....#.	13	#....#.	23	15
0	T	11	..#.##.	12	..#.##.	23	15
0	T	12	..#.##.	11	..#.##.	23	15
0	T	13	#....#.	10	#....#.	23	15
0	T	15	...####	8	...####	23	15

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT
0	B	1	...####	8	...####	9	15
0	B	3	#....#.	6	#....#.	9	15
0	B	4	..#.##.	5	..#.##.	9	15
0	B	5	..#.##.	4	..#.##.	9	15
0	B	6	#....#.	3	#....#.	9	15
0	B	8	...####	1	...####	9	15
0	B	12	...##.#	15	...##.#	27	15
0	B	13	.##.###	14	.##.###	27	15
0	B	14	.##.###	13	.##.###	27	15
0	B	15	...##.#	12	...##.#	27	15

so in this case, it is 1,2,3,4 because they are contiguous
  , also answer needs even number of rows because creases are between rows
*/
create or replace view b13 as
select mirror_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , row_number() over (partition by mirror_id, orientation order by the_row1) the_rownum
from line_matches
--where mirror_id = 0
--  and orientation='T'
order by mirror_id,orientation, key, the_row1;

/*
4	1	.#..#.##.	15	15
4	2	##..####.	15	14
4	3	.#..#..#.	15	13
4	4	..##....#	15	12
4	5	.#..#..#.	15	11
4	6	.#..#.###	15	10
4	7	........#	15	9
4	8	......#.#	15	8
4	9	##..##.##	15	7
4	10	##..##.#.	15	6
4	11	##..##...	15	5
4	12	##..##.##	15	4
4	13	......#.#	15	3
4	14	........#	15	2
4	15	.#..#.###	15	1

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT	THE_ROWNUM
4	B	1	.#..#.###	10	.#..#.###	11	15	1
4	B	2	........#	9	........#	11	15	2
4	B	3	......#.#	8	......#.#	11	15	3
4	B	4	##..##.##	7	##..##.##	11	15	4
4	B	7	##..##.##	4	##..##.##	11	15	5
4	B	8	......#.#	3	......#.#	11	15	6
4	B	9	........#	2	........#	11	15	7
4	B	10	.#..#.###	1	.#..#.###	11	15	8
4	B	11	.#..#..#.	13	.#..#..#.	24	15	9
4	B	13	.#..#..#.	11	.#..#..#.	24	15	10
4	L	1	.#......####...	6	.#......####...	7	9	1
4	L	2	###.##..####..#	5	###.##..####..#	7	9	2
4	L	3	...#...........	4	...#...........	7	9	3
4	L	4	...#...........	3	...#...........	7	9	4
4	L	5	###.##..####..#	2	###.##..####..#	7	9	5
4	L	6	.#......####...	1	.#......####...	7	9	6

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT	THE_ROWNUM
4	B	1	.#..#.###	10	.#..#.###	11	15	1
4	B	2	........#	9	........#	11	15	2
4	B	3	......#.#	8	......#.#	11	15	3
4	B	4	##..##.##	7	##..##.##	11	15	4
4	L	1	.#......####...	6	.#......####...	7	9	1
4	L	2	###.##..####..#	5	###.##..####..#	7	9	2
4	L	3	...#...........	4	...#...........	7	9	3
4	L	4	...#...........	3	...#...........	7	9	4
4	L	5	###.##..####..#	2	###.##..####..#	7	9	5
4	L	6	.#......####...	1	.#......####...	7	9	6

*/

create or replace view b13 as
select mirror_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , rank() over (partition by mirror_id, orientation order by the_row1) the_rank
from line_matches
--where mirror_id = 0
--  and orientation='T'
order by mirror_id,orientation, key, the_row1;
select * from b13;

select * from b13
where 1=1
--  and mirror_id = 4
--  and (orientation='B' or orientation = 'L')
  and the_rank+1 = key
order by mirror_id,orientation, key, the_row1;
-- looks good until 10..
/*
MIRROR_ID	X	X_LINE	NUM_LINES
10	1	..#.....#	15
10	2	.###.#.##	15
10	3	##...##..	15
10	4	#......#.	15
10	5	#.###..##	15
10	6	#.#.#..##	15
10	7	#......#.	15
10	8	#.##..##.	15
10	9	#.###.###	15
10	10	#.###.###	15
10	11	#.##..##.	15
10	12	#......#.	15
10	13	#.#.#..##	15
10	14	#.###..##	15
10	15	#......#.	15

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT	THE_RANK
10	B	8	#.##..##.	5	#.##..##.	13	15	12
10	T	15	#......#.	4	#......#.	19	15	18

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT
10	B	1	#......#.	4	#......#.	5	15
10	B	4	#......#.	1	#......#.	5	15
10	B	1	#......#.	9	#......#.	10	15
10	B	9	#......#.	1	#......#.	10	15
10	B	1	#......#.	12	#......#.	13	15
10	B	2	#.###..##	11	#.###..##	13	15
10	B	3	#.#.#..##	10	#.#.#..##	13	15
10	B	4	#......#.	9	#......#.	13	15
10	B	5	#.##..##.	8	#.##..##.	13	15
10	B	6	#.###.###	7	#.###.###	13	15
10	B	7	#.###.###	6	#.###.###	13	15
10	B	8	#.##..##.	5	#.##..##.	13	15
10	B	9	#......#.	4	#......#.	13	15
10	B	10	#.#.#..##	3	#.#.#..##	13	15
10	B	11	#.###..##	2	#.###..##	13	15
10	B	12	#......#.	1	#......#.	13	15
10	B	4	#......#.	12	#......#.	16	15
10	B	12	#......#.	4	#......#.	16	15
10	B	9	#......#.	12	#......#.	21	15
10	B	12	#......#.	9	#......#.	21	15

MIRROR_ID	ORIENTATION	THE_ROW1	THE_LINE1	THE_ROW2	THE_LINE2	KEY	TOT
10	T	4	#......#.	7	#......#.	11	15
10	T	7	#......#.	4	#......#.	11	15
10	T	4	#......#.	12	#......#.	16	15
10	T	12	#......#.	4	#......#.	16	15
10	T	4	#......#.	15	#......#.	19	15
10	T	5	#.###..##	14	#.###..##	19	15
10	T	6	#.#.#..##	13	#.#.#..##	19	15
10	T	7	#......#.	12	#......#.	19	15
10	T	8	#.##..##.	11	#.##..##.	19	15
10	T	9	#.###.###	10	#.###.###	19	15
10	T	10	#.###.###	9	#.###.###	19	15
10	T	11	#.##..##.	8	#.##..##.	19	15
10	T	12	#......#.	7	#......#.	19	15
10	T	13	#.#.#..##	6	#.#.#..##	19	15
10	T	14	#.###..##	5	#.###..##	19	15
10	T	15	#......#.	4	#......#.	19	15
10	T	7	#......#.	15	#......#.	22	15
10	T	15	#......#.	7	#......#.	22	15
10	T	12	#......#.	15	#......#.	27	15
10	T	15	#......#.	12	#......#.	27	15

*/
-- well, plenty of cases where rank+1 = key...

create or replace view b13 as
select mirror_id, orientation, the_row1, the_line1, the_row2, the_line2, key, tot
  , count(*) over (partition by mirror_id, orientation, key) the_count
  , max(the_row1) over (partition by mirror_id, orientation, key) the_max
from line_matches
--where mirror_id = 0
--  and orientation='T'
--order by mirror_id,orientation, key, the_row1;
;
select * from b13 where the_count = the_max and the_row1 = the_max;

create or replace view a as
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from b13
where the_count = the_max and the_row1 = the_max;
select sum(multiplier*num_lines) from a;
