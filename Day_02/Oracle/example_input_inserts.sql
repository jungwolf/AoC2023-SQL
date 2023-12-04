exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day02_example','table');
create table day02_example (lineno number, linevalue varchar2(4000));

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green');

commit;
