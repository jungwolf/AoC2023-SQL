exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day09_example','table');
create table day09_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day09_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'0 3 6 9 12 15');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'1 3 6 10 15 21');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'10 13 16 21 30 45');

commit;
