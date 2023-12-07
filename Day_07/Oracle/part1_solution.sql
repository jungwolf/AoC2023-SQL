-- example worked for part 1
create or replace synonym input_data for day07_part1;
select sum(bid*rank) answer from hand_bid_rank;
