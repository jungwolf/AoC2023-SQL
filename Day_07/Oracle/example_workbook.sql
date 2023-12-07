-- scratchpad for creating the solution
create or replace synonym input_data for day07_example;

select * from input_data;

-- split hand from
select i.lineno hand_id, i.linevalue
--  ,instr(i.linevalue,' ')
  ,substr(i.linevalue,1,instr(i.linevalue,' ')) cards
  ,to_number(substr(i.linevalue,instr(i.linevalue,' ')+1)) bid
from input_data i
/
create or replace view hands as
select i.lineno hand_id
--  , i.linevalue
--  ,instr(i.linevalue,' ')
  ,substr(i.linevalue,1,instr(i.linevalue,' ')) cards
  ,to_number(substr(i.linevalue,instr(i.linevalue,' ')+1)) bid
from input_data i
/
select * from hands;

select i.lineno, i.linevalue, n.id, n.column_value
from input_data i
  ,lateral(select rownum id, column_value from table( string2rows(i.linevalue,' ')) where column_value is not null) n
;

select h.hand_id, h.cards, h.bid, n.card_id, n.card
from hands h
  ,lateral(select rownum card_id, column_value card from table( string2rows(h.cards))) n
;
create or replace view cards_in_hands as
select h.hand_id
--  , h.cards
  , h.bid
  , n.id card_position
  , n.column_value card_face
from hands h
  ,lateral(select rownum id, column_value from table( string2rows(h.cards))) n
;
select * from cards_in_hands;

select c.hand_id, card_face, count(*)
from cards_in_hands c
group by c.hand_id, c.card_face
order by 1,3 desc
;
-- looking good

--okay, build the reference tables
create or replace view card_values as
select card_face
  , case card_face
      when 'T' then 10
      when 'J' then 11
      when 'Q' then 12
      when 'K' then 13
      when 'A' then 14
      else to_number(card_face)
    end card_value
from cards_in_hands
group by card_face
/
select * from card_values
;
