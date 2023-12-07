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

select 
'5' pattern
, 7 tier
,'Five of a kind, where all five cards have the same label: AAAAA' description
from dual
union all select '4',6,'Four of a kind, where four cards have the same label and one card has a different label: AA8AA' from dual
union all select '32',5,'Full house, where three cards have the same label, and the remaining two cards share a different label: 23332' from dual
union all select '3',4,'Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98' from dual
union all select '22',3,'Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432' from dual
union all select '2',2,'One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4' from dual
union all select '1',1,'High card, where all cards'' labels are distinct: 23456' from dual
/

create or replace view hand_values as
select
'5' pattern
, 7 tier
,'Five of a kind, where all five cards have the same label: AAAAA' description
from dual
union all select '4',6,'Four of a kind, where four cards have the same label and one card has a different label: AA8AA' from dual
union all select '32',5,'Full house, where three cards have the same label, and the remaining two cards share a different label: 23332' from dual
union all select '3',4,'Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98' from dual
union all select '22',3,'Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432' from dual
union all select '2',2,'One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4' from dual
union all select '1',1,'High card, where all cards'' labels are distinct: 23456' from dual
/
select * from hand_values;

select * from hand_values;
select * from card_values;
select hand_id, listagg(card_count) within group (order by card_count desc)
from (
  select c.hand_id, card_face, count(*) card_count
  from cards_in_hands c
  group by c.hand_id, c.card_face
)
group by hand_id
order by 1
;

create or replace view shape_of_hands as
select hand_id, listagg(card_count) within group (order by card_count desc) shape
from (
  select c.hand_id, card_face, count(*) card_count
  from cards_in_hands c
  group by c.hand_id, c.card_face
)
group by hand_id
order by 1
;
select * from shape_of_hands;
