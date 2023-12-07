create or replace synonym input_data for day07_example;

select * from hands;
select * from cards_in_hands;
select * from card_values;
select * from hand_shape_values;
select * from shape_of_hands;
select * from hand_shape_values;
select * from a;
select * from b;
select * from hand_bid_rank;

--create or replace view shape_of_hands as
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
order by hand_id, card_count
/

create or replace view shape_of_hands as
select hand_id, listagg(to_char(count_with_jokers)) within group (order by count_with_jokers desc) shape
from (
  select c.hand_id
    , card_face
    , count(*) card_count
    , sum(decode(card_face,'J',1,0)) over (partition by hand_id) joker_count
    , case when card_face = 'J' then count(*)
        else count(*) + sum(decode(card_face,'J',1,0)) over (partition by hand_id)
      end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
)
group by hand_id, joker_count
order by 1
;


create or replace view shape_of_hands as
select hand_id, listagg(to_char(count_with_jokers)) within group (order by count_with_jokers desc) shape
from (
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
)
group by hand_id, joker_count
order by 1
;
/

select * from shape_of_hands;
select * from hand_shape_values;
select * from a;
select * from b;
select * from hand_bid_rank;

select sum(bid*rank) answer from hand_bid_rank;


----------------------------------------------------------------- start again
create or replace synonym input_data for day07_example;

select * from hands;
select * from cards_in_hands;
select * from card_values;
select * from hand_shape_values;
select * from shape_of_hands;
select * from hand_shape_values;
select * from a;
select * from b;
select * from hand_bid_rank;

--create or replace view shape_of_hands as
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
order by hand_id, card_count
/

create or replace view shape_of_hands as
select hand_id, listagg(to_char(count_with_jokers)) within group (order by count_with_jokers desc) shape
from (
  select c.hand_id
    , card_face
    , count(*) card_count
    , sum(decode(card_face,'J',1,0)) over (partition by hand_id) joker_count
    , case when card_face = 'J' then count(*)
        else count(*) + sum(decode(card_face,'J',1,0)) over (partition by hand_id)
      end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
)
group by hand_id, joker_count
order by 1
;


create or replace view shape_of_hands as
select hand_id, listagg(to_char(count_with_jokers)) within group (order by count_with_jokers desc) shape
from (
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
)
group by hand_id, joker_count
order by 1
;

select * from shape_of_hands;
select * from hand_shape_values;
select * from a;
select * from b;
select * from hand_bid_rank;

select sum(bid*rank) answer from hand_bid_rank;
create or replace synonym input_data for day07_part1;
select sum(bid*rank) answer from hand_bid_rank;
-- too low

create or replace synonym input_data for day07_example;

/* say there is 1 joker and 2 of something else, like 1123J
the normal shape is 2111, and currenly joker adds 1 to all but itself, 3221
but that matches a full house, when it really is only 3 of a kind
so fix that...

create or replace view shape_of_hands as
select hand_id, listagg(to_char(count_with_jokers)) within group (order by count_with_jokers desc) shape
from (
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
)
group by hand_id, joker_count
order by 1
;
*/
select c.hand_id
  , card_face
  , count(*) card_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , case when card_face = 'J' then count(*)
      else count(*) + sum(decode(card_face,'J',count(*),0)) over (partition by hand_id)
    end count_with_jokers
from cards_in_hands c
group by c.hand_id, c.card_face
;

select c.hand_id
  , card_face
  , count(*)
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , nth_value(count(*),1) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(count(*),2) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from cards_in_hands c
group by c.hand_id, c.card_face
order by hand_id
;



select *
from (
select c.hand_id
  , card_face
  , count(*)
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
  , nth_value(count(*),1) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(count(*),2) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from cards_in_hands c
group by c.hand_id, c.card_face
)
where card_face != 'J'
;

select hand_id
--  , joker_count
  , max(joker_count)
  , nth_value(the_count,1) over (partition by hand_id order by the_count desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(the_count,2) over (partition by hand_id order by the_count desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from (
select c.hand_id
  , card_face
  , count(*) the_count
  , sum(decode(card_face,'J',count(*),0)) over (partition by hand_id) joker_count
from cards_in_hands c
group by c.hand_id, c.card_face
)
where card_face != 'J'
--group by hand_id, the_count, joker_count
group by hand_id, the_count;

select unique c.hand_id
--  , card_face
--  , count(*) card_count
  , nth_value(count(*),1) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(count(*),2) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from cards_in_hands c
where card_face != 'J'
group by c.hand_id, c.card_face
order by hand_id, t3 desc, t4
;

select c.hand_id
  , card_face
  , count(*) card_count
from cards_in_hands c
where card_face = 'J'
group by c.hand_id, c.card_face
order by hand_id, card_count desc
;

create or replace view hand_top_cards as
select unique c.hand_id
--  , card_face
--  , count(*) card_count
  , nth_value(count(*),1) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t3
  , nth_value(count(*),2) over (partition by hand_id order by count(*) desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) t4
from cards_in_hands c
where card_face != 'J'
group by c.hand_id, c.card_face
--order by hand_id, t3 desc, t4
;
select * from hand_top_cards;

create or replace view hand_jokers as
select c.hand_id
  , card_face
  , count(*) card_count
from cards_in_hands c
where card_face = 'J'
group by c.hand_id, c.card_face
order by hand_id, card_count desc
;
select * from hand_jokers;

create or replace view shape_of_hands as
select t.hand_id
--, t3+(nvl(j.card_count,0)),t4
, to_char(t3+(nvl(j.card_count,0)))||to_char(t4) shape
from hand_top_cards t, hand_jokers j
where t.hand_id=j.hand_id (+)
/
select * from shape_of_hands order by hand_id;
-- missing 870
select * from hands where hand_id = 870;
--HAND_ID	CARDS	BID
--870	JJJJJ	90

select t.hand_id, j.hand_id
, coalesce(t.hand_id, j.hand_id)
--, t3+(nvl(j.card_count,0)),t4
, to_char(nvl(t3,0)+(nvl(j.card_count,0)))||to_char(nvl(t4,0)) shape
from hand_top_cards t
full outer join hand_jokers j on t.hand_id=j.hand_id
--where coalesce(t.hand_id,j.hand_id) = 870
--where j.hand_id = 870
where coalesce(t.hand_id, j.hand_id)=870
order by t.hand_id, j.hand_id
/

create or replace view shape_of_hands as
select coalesce(t.hand_id, j.hand_id) hand_id
, to_char(nvl(t3,0)+(nvl(j.card_count,0)))||to_char(nvl(t4,0)) shape
from hand_top_cards t
full outer join hand_jokers j on t.hand_id=j.hand_id
/
select * from shape_of_hands;

create or replace synonym input_data for day07_part1;

select * from card_values;
select * from hand_shape_values;
select * from hands;
select * from cards_in_hands;
select * from shape_of_hands;
select * from a;
select * from b;
select * from hand_bid_rank;
select sum(bid*rank) answer from hand_bid_rank;

