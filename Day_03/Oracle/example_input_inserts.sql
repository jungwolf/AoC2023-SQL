exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day03_example','table');
create table day03_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day03_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'467..114..');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'...*......');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..35..633.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'......#...');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'617*......');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'.....+.58.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'..592.....');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'......755.');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'...$.*....');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'.664.598..');

commit;

