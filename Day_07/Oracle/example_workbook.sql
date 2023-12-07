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
  ,substr(i.linevalue,1,instr(i.linevalue,' ')-1) cards
  ,to_number(substr(i.linevalue,instr(i.linevalue,' ')+1)) bid
from input_data i
/
select * from hands;

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

create or replace view hand_shape_values as
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
select hand_id, listagg(to_char(card_count)) within group (order by card_count desc) shape
from (
  select c.hand_id, card_face, count(*) card_count
  from cards_in_hands c
  group by c.hand_id, c.card_face
)
group by hand_id
order by 1
;

/*
whoops, already did this one as shape_of_hands
select c.hand_id
--  , card_face
--  , count(*)
--  , listagg(to_char(count(*))) within group (order by count(*) desc) over (partition by hand_id) hand_shape_total
  , substr(listagg(to_char(count(*))) within group (order by count(*) desc) over (partition by hand_id),1,2) hand_shape
from cards_in_hands c
group by c.hand_id, c.card_face
order by c.hand_id, count(*) desc
;
*/
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

select * from hands;
select * from hand_shape_values ;
select * from card_values;
select * from shape_of_hands;
select * from cards_in_hands;

select h.hand_id, h.cards, h.bid
  , s.shape
  , (select tier from hand_shape_values v where v.pattern like s.shape order by tier desc fetch first 1 rows only) tier
from hands h, shape_of_hands s
where h.hand_id = s.hand_id
;
/* tier is null...
HAND_ID	CARDS	BID	SHAPE	TIER
1	32T3K	765	2111
2	T55J5	684	311
3	KK677	28	221
4	KTJJT	220	221
5	QQQJA	483	311
*/

select *
from hand_shape_values v, shape_of_hands s
where s.shape like v.pattern
/

select h.hand_id, h.cards, h.bid
  , s.shape
  , (select tier from hand_shape_values v where v.pattern like s.shape order by tier desc fetch first 1 rows only) tier
  , v1.*
from hands h, shape_of_hands s, hand_shape_values v1
where h.hand_id = s.hand_id
;

select * from dual where '2111' like '2%';
select * from dual where to_char('2111') like '2%';

select h.hand_id, h.cards, h.bid
  , s.shape
  , (select tier from hand_shape_values v where s.shape like v.pattern order by tier desc fetch first 1 rows only) tier
from hands h, shape_of_hands s
where h.hand_id = s.hand_id
;

select * from hand_shape_values ;
select * from card_values;
select * from hands;
select * from shape_of_hands;
select * from cards_in_hands;

create or replace view a as
select h.hand_id
--  , h.cards
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

select a.*, b.*
from a,b
where a.hand_id = b.hand_id;

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
select sum(bid*rank) from hand_bid_rank;
