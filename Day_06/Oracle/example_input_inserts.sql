exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day06_example','table');
create table day06_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day06_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Time:      7  15   30');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Distance:  9  40  200');

commit;


