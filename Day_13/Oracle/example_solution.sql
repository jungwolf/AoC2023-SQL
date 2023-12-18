create or replace synonym input_data for day13_example;

/*
 assign a mirror_id to each grouping of lines between nulls
the sum line is keeping a running sum of blank lines
no blanks before the first set of lines, so they have mirror_id=0
##.	0 blanks, mirror_id=0
.##	0 blanks, mirror_id=0
  <- a blank line, mirror_id=1
..#	1 blank, mirror_id=1
.##	1 blank, mirror_id=1
blank lines themselves are not part of a mirror so we'll filter them out later
*/
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
select * from xline;

-- I need to transpose the columns to rows within a mirror_id
-- this view gives me the an x,y coordinate so I can then use y,x
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

-- group the rows by y, and put them together in x order to get a full line
create or replace view yline as
select
  mirror_id
  , y
  , listagg(cell) within group (order by x) y_line
from xy
group by mirror_id, y
/


-- to simplify things, let's build a view that has the 4 orientation to look at the mirrors
-- orientation=> what line starts row1, T=>top down, B=>bottom up, L=>left, R=>right

-- keep in mind, a proper mirror starts at an edge
-- only one of the four orientation should have valid reflection that starts on row 1
-- calculate the total number of rows, too, that will come in handy

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

-- match all the rows! except don't match to itself
-- this is a self-join, both a1 and a2 reference the same table.
-- key => a1.the_row + a2.the_row , can be used to find the reflection line
create or replace view line_matches as
select a1.mirror_id, a1.orientation, a1.the_row the_row1, a1.the_line the_line1, a2.the_row the_row2, a2.the_line the_line2
  , a1.the_row + a2.the_row key, a1.tot
from all_orientations a1, all_orientations a2
where 1=1
  and a1.mirror_id = a2.mirror_id
  and a1.orientation = a2.orientation
  and a1.the_line = a2.the_line
  and a1.the_row != a2.the_row
order by a1.mirror_id, a1.the_row, a1.the_row + a2.the_row;
select * from line_matches order by mirror_id,orientation, key, the_row1;

/* if orientation ..
  T => #lines = count(*) < crease (above the crease), horizontal so *100
  B => #lines = count(*) > crease (flipped...), horizontal so *100
  L => #lines = count(*) < crease, *1
  R -> #lines = count(*) > crease, *1
*/
-- row 1 should have the values needed for the answer
create or replace view a as
select mirror_id, orientation, the_row1, the_row2, key, key/2 crease, tot
  , decode(orientation,'T',trunc(key/2),'B',tot-trunc(key/2),'L',trunc(key/2),'R',tot-trunc(key/2)) num_lines
  , decode(orientation,'T',100,'B',100,'L',1,'R',1) multiplier
from line_matches
where the_row1 = 1;

-- analytic function happen as the last step
-- if I want to do a sum(), need to do it after generating the analytic values
select sum(multiplier*num_lines) from a;

-- worked!