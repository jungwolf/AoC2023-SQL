-- Sample
create or replace synonym input_data for day09_example;

/*
In particular, here is what the third example history looks like when extrapolating back in time:

5  10  13  16  21  30  45
  5   3   3   5   9  15
   -2   0   2   4   6
      2   2   2   2
        0   0   0
*/
-- putting it back together for sample 3, to compare with the part2 example
select history_id
  , rpad(' ',4*diff_level)
    || listagg(to_char(value,'99'),' ') within group (order by seq_num)
  , diff_level
from pyramid
where history_id = 3
group by history_id,diff_level
;
/*
 10  13  16  21  30  45
      3   3   5   9  15
          0   2   4   6
              2   2   2
                  0   0
                      0
oh, don't need rpad
*/
select 
    listagg(to_char(value,'99'),' ') within group (order by seq_num)
from pyramid
where history_id = 3
group by history_id,diff_level
;
/*
 10  13  16  21  30  45
  3   3   5   9  15
  0   2   4   6
  2   2   2
  0   0
  0

5  10  13  16  21  30  45
5   3   3   5   9  15
-2  0   2   4   6
2   2   2   2
0   0   0

x0 x1 x2...
0
0   0
0   0   0
2   2   2   2
-2  0   2   4   6
5   3   3   5   9  15
5  10  13  16  21  30  45

looks like
new line x0 = new line x1 - old line x0, ordering by diff_level desc
*/
-- check with line 3
with sequences as (
  select /*+ materialize */
    to_number(i.lineno) history_id
    , n.id seq_num
    , to_number(n.column_value) value
  from input_data i
    ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
  where i.to_number(i.lineno) = 3
)
, pyramid (history_id, seq_num, value, diff_level) as (
  select history_id, seq_num, value, 0
  from sequences

  union all

  select history_id, seq_num
    , value - lag(value,1) over (partition by history_id order by seq_num)
    , diff_level +1
  from pyramid
  where diff_level < 1000
    and value is not null
)
select history_id
  , listagg(to_char(value,'99'),' ') within group (order by seq_num)
  , diff_level
from pyramid
group by history_id,diff_level
;
;
/*
3	 10  13  16  21  30  45	0
3	  3   3   5   9  15	1
3	  0   2   4   6	2
3	  2   2   2	3
3	  0   0	4
3	  0	5
3		6
*/
--..
select *
from pyramid
where value is not null
order by seq_num, diff_level
;
--..
select *
from pyramid
where value is not null
  and seq_num = diff_level + 1
order by diff_level desc
;
--..
select history_id, seq_num, value, diff_level
  , value
  , lag(value,1) over (partition by history_id order by diff_level desc) lagvalue
  , value - lag(value,1) over (partition by history_id order by diff_level desc) diff_val_lag
from pyramid
where value is not null
  and seq_num = diff_level + 1
order by diff_level desc
;
/*
3	6	0	5	0		
3	5	0	4	0	0	0
3	4	2	3	2	0	2
3	3	0	2	0	2	-2
3	2	3	1	3	0	3
3	1	10	0	10	3	7

  , value - lag(value,1) over (partition by history_id order by diff_level desc) diff_val_lag
seq_num	diff_level	value	lagvalue	diff_val_lag
6	5	0		
5	4	0	0	0
4	3	2	0	2
3	2	0	2	-2
2	1	3	0	3
1	0	10	3	7

0		
0	0	0
2	0	2
0	2	-2
3	0	3
10	3	7

x0 x1 x2...
0
0   0
0   0   0
2   2   2   2
-2  0   2   4   6
5   3   3   5   9  15
5  10  13  16  21  30  45

looks like
new line x0 = new line x1 - old line x0, ordering by diff_level desc
*/

/*
let's get more examples
   0 3 6 9 12 15
     3 3 3  3  3
       0 0  0  0
-- so should be
     0 0 0  0  0
   3 3 3 3  3  3
-3 0 3 6 9 12 15
-3

  1 3 6 10 15 21
    2 3  4  5  6
      1  1  1  1
-- so should be 
      0  0  0  0
    1 1  1  1  1
  1 2 3  4  5  6
0 1 3 6 10 15 21
0

  10 13 16 21 30 45
      3  3  5  9 15
         0  2  4  6
            2  2  2
               0  0
--
            0  0  0
         2  2  2  2
     -2  0  2  4  6
   5  3  3  5  9 15
5 10 13 16 21 30 45
5


 0  0 => x0 = x1 - oldx0 =>  0  -  0 =  0
 3  3 -> x0 = x1 - oldx0 =>  3  -  0 =  3
-3  0 -> x0 = x1 - oldx0 =>  0  -  3 = -3

 0  0 => x0 = x1 - oldx0 =>  0  -  0 =  0
 1  1 -> x0 = x1 - oldx0 =>  1  -  0 =  1
 1  2 -> x0 = x1 - oldx0 =>  2  -  1 =  1
 0  1 => x0 = x1 - oldx0 =>  1  -  1 =  0

 0  0 => x0 = x1 - oldx0 =>  0  -  0 =  0
 2  2 => x0 = x1 - oldx0 =>  2  -  0 =  2
-2  0 => x0 = x1 - oldx0 =>  0  -  2 = -2
 5  3 => x0 = x1 - oldx0 =>  3  - -2 =  5
 5 10 => x0 = x1 - oldx0 => 10  -  5 =  5

?? seq_num	diff_level	value	lagvalue	diff_val_lag
?? value - lag(value,1) over (partition by history_id order by diff_level desc) diff_val_lag

*/
