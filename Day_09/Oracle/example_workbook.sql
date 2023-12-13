-- scratchpad for creating the solution
create or replace synonym input_data for day09_example;

select * from input_data;

-- get the elements
select
  i.lineno history_id
  , n.id seq_num
  , n.column_value value
from input_data i
  ,lateral(select rownum id, column_value from table(string2rows(i.linevalue,' '))) n
;
/* so, histories are basically this:
x, x+y, x+y+z, x+y+z, x+y+z... while the new element is > 0
oh, that's diff, so normalize the sequence to 0

-- no
let's call the list X and elements are numbered x(0), x(1), x(2), ...
Let c=x(0)
Then X -> c, (x(1)-c)+c, (x(2)-c)+c, ...
and we can "take out" c for X' -> 0, x(1), x(2), ...

I guess more x(0)+c,x(0)+x(1)+c, x(0)+x(1)+x(2)+c .. while x(n) > 0
where c=x, x(0) = 0, x(1) = y, and x(n+1)=x(n)-x(n-1) while x(n) > 0

check:
0 3 6 9 12 15
c=0, x(1)=3