create or replace synonym input_data for day07_part1;

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
select * from card_values;

create or replace view hand_shape_values as
select
'5%' pattern
, 7 tier
,'Five of a kind, where all five cards have the same label: AAAAA' description
from dual
union all select '4%',6,'Four of a kind, where four cards have the same label and one card has a different label: AA8AA' from dual
union all select '32%',5,'Full house, where three cards have the same label, and the remaining two cards share a different label: 23332' from dual
union all select '3%',4,'Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98' from dual
union all select '22%',3,'Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432' from dual
union all select '2%',2,'One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4' from dual
union all select '1%',1,'High card, where all cards'' labels are distinct: 23456' from dual
/
select * from hand_shape_values;

create or replace view hands as
select i.lineno hand_id
  ,substr(i.linevalue,1,instr(i.linevalue,' ')-1) cards
  ,to_number(substr(i.linevalue,instr(i.linevalue,' ')+1)) bid
from input_data i
/
select * from hands;

create or replace view cards_in_hands as
select h.hand_id
  , h.bid
  , n.id card_position
  , n.column_value card_face
from hands h
  ,lateral(select rownum id, column_value from table( string2rows(h.cards))) n
;
select * from cards_in_hands;

create or replace view hand_top_cards as
select unique c.hand_id
  , nth_value(count(*),1) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(count(*),2) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from cards_in_hands c
where card_face != 'J'
group by c.hand_id, c.card_face
;
select * from hand_top_cards;

create or replace view hand_jokers as
select c.hand_id
  , card_face
  , count(*) card_count
from cards_in_hands c
where card_face = 'J'
group by c.hand_id, c.card_face
;
select * from hand_jokers;

create or replace view shape_of_hands as
select coalesce(t.hand_id, j.hand_id) hand_id
, to_char(nvl(t3,0)+(nvl(j.card_count,0)))||to_char(nvl(t4,0)) shape
from hand_top_cards t
full outer join hand_jokers j on t.hand_id=j.hand_id
/
select * from shape_of_hands;

create or replace view a as
select h.hand_id
  , h.bid
  , n.id card_position
  , n.column_value card_face
  , (select card_value from card_values where card_face = n.column_value) card_value
  , (select card_value from card_values where card_face = n.column_value)*power(16,5-n.id) position_value
from hands h
  ,lateral(select rownum id, column_value from table( string2rows(h.cards))) n
;
select * from a;

create or replace view b as
select h.hand_id, h.cards, h.bid
  , s.shape
  , (select tier from hand_shape_values v where s.shape like v.pattern order by tier desc fetch first 1 rows only) tier
from hands h, shape_of_hands s
where h.hand_id = s.hand_id
;
select * from b;

create or replace view hand_bid_rank as
select
  a.hand_id, a.bid
  , b.tier
  , sum(a.position_value) cards_value
  , rank() over (order by b.tier, sum(a.position_value)) rank
from a,b
where a.hand_id = b.hand_id
group by a.hand_id, a.bid, b.tier
;
select * from hand_bid_rank;

select sum(bid*rank) answer from hand_bid_rank;

