-- scratchpad for creating the solution
create or replace synonym input_data for day03_example;

select * from input_data;

/*
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..


General idea is check a box around the part numbers to see if a symble is in it
find symbol positions
find part number positions
symbol x,y in -1,-1 begining to +1,+1 end

sum the part numbers that have a symbol close by
*/
-- find engine_schematic size
create or replace view schematic_size as (
  select count(*) y, max(length(linevalue)) z
  from input_data
);
select * from schematic_size; 
--Y	Z
--10	10

-- not sure if needed, but go with it for now
-- pad the engine schematic to get rid of constant bounds checking
-- keep that in mind if we need to work in absolute values based on the original
--   y isn't affected, but x is shifted by +1
SELECT rpad('.',15,'.') "LPAD example" FROM DUAL;

create or replace view engine_schematic as 
select 0 lineno, rpad('.',x,'.') the_row from schematic_size
union all select lineno, linevalue from input_data
union all select y+1, rpad('.',x,'.') the_row from schematic_size
/
select * from engine_schematic;
/*
LINENO	THE_ROW
0	..........
1	467..114..
2	...*......
...
*/

-- maybe split lines into the non-'.' parts
select 
  *
from engine_schematic e
  ,lateral(select rownum id, column_value part, length(column_value) part_size  from table( string2rows(e.the_row,'.') )) n
where n.part is not null
/
/*
LINENO	THE_ROW	ID	PART	PART_SIZE
4	......#...	7	#	1
5	617*......	1	617*	4
6	.....+.58.	6	+	1
6	.....+.58.	7	58	2

Almost right
didn't think about symbols L,R of the part
*/
