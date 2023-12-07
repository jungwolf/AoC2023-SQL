exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day07_example','table');
create table day07_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day07_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'32T3K 765');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'T55J5 684');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'KK677 28');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'KTJJT 220');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'QQQJA 483');

commit;
