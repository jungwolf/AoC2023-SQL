exec drop_object_if_exists('line_number_sq','sequence');
create sequence line_number_sq;

exec drop_object_if_exists('day19_example','table');
create table day19_example (lineno number, linevalue varchar2(4000));

create or replace synonym input_data for day19_example;

--insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'
--');

insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'px{a<2006:qkq,m>2090:A,rfg}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'pv{a>1716:R,A}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'lnx{m>1548:A,A}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'rfg{s<537:gd,x>2440:R,A}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'qs{s>3448:A,lnx}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'qkq{x<1416:A,crn}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'crn{x>2662:A,R}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'in{s<1351:px,qqz}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'qqz{s>2770:qs,m<1801:hdj,R}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'gd{a>3333:R,R}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'hdj{m>838:A,pv}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'{x=787,m=2655,a=1222,s=2876}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'{x=1679,m=44,a=2067,s=496}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'{x=2036,m=264,a=79,s=2244}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'{x=2461,m=1339,a=466,s=291}');
insert into input_data (lineno, linevalue) values (line_number_sq.nextval,'{x=2127,m=1623,a=2188,s=1013}');

commit;
