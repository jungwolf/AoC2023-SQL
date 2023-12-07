create or replace synonym input_data for day07_part1;
-- using day07_example data for sample output

/*
The puzzle gives us hands of cards and rules to score the hands. We need to get the scores to solve the problem.
*/

-- parse input into ids and string of cards
-- ids are the line numbers, linevalue split on ' ' to get cards and bid
create or replace view hands as
select i.lineno hand_id
  ,substr(i.linevalue,1,instr(i.linevalue,' ')-1) cards
  ,to_number(substr(i.linevalue,instr(i.linevalue,' ')+1)) bid
from input_data i
/
/*
HAND_ID	CARDS	BID
1	32T3K	765
2	T55J5	684
*/

-- split up the cards string into individual cards
-- like normal, use the lateral join to split the source row into multiple rows
create or replace view cards_in_hands as
select h.hand_id
  , n.id card_position
  , n.column_value card_face
from hands h
  ,lateral(select rownum id, column_value from table( string2rows(h.cards))) n
;
/*
HAND_ID	BID	CARD_POSITION	CARD_FACE
1	765	1	3
1	765	2	2
...			
2	684	4	J
2	684	5	5
...
*/

/*
we're given the relative ranking of the cards. This is a lookup table.
It's needlessly wasteful, I dynamically grab the numeric values from the data which scans everything.
Hopefully the optimizer creates an in-memory temp table instead of scanning the table whenever the view is used.
*/
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
/*
CARD_FACE	CARD_VALUE
J	11
6	6
2	2
*/

/*
The second lookup table to find the hand type. This poker doesn't have suits, so hands are score by 

-------- stopped here..
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
create or replace view b as
select h.hand_id, h.cards, h.bid
  , s.shape
  , (select tier from hand_shape_values v where s.shape like v.pattern order by tier desc fetch first 1 rows only) tier
from hands h, shape_of_hands s
where h.hand_id = s.hand_id
;

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

select sum(bid*rank) answer from hand_bid_rank;
