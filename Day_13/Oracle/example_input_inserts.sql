exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day13_example','table');
create table day13_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day13_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#.##..##.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..#.##.#.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'##......#');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'##......#');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..#.##.#.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..##..##.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#.#.##.#.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#...##..#');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#....#..#');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..##..###');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#####.##.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#####.##.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..##..###');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'#....#..#');

commit;

