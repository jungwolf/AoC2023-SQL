exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day08_example1','table');
create table day08_example1 (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day08_example1;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');
-- sample one --
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'RL');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'AAA = (BBB, CCC)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'BBB = (DDD, EEE)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'CCC = (ZZZ, GGG)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'DDD = (DDD, DDD)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'EEE = (EEE, EEE)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'GGG = (GGG, GGG)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'ZZZ = (ZZZ, ZZZ)');

commit;

exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;
exec drop_object_if_exists('day08_example2','table');
create table day08_example2 (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day08_example2;


-- sample two --
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'LLR');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'AAA = (BBB, BBB)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'BBB = (AAA, ZZZ)');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'ZZZ = (ZZZ, ZZZ)');

commit;
