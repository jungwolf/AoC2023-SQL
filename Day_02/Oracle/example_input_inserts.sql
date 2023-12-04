exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day??_example','table');
create table day??_example (lineno number, linevalue varchar2(4000));

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

commit;
