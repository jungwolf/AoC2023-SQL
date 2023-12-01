exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day01_example','table');
create table day01_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day01_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'1abc2');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'pqr3stu8vwx');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'a1b2c3d4e5f');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'treb7uchet');

commit;
