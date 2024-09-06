/* Prep work ahead of the class: */
create index posts_owneruserid on public.posts using btree(owneruserid);
create index posts_score_owneruserid on public.posts using btree(score, owneruserid);




select * from users limit 100;

select * from users where location = 'Las Vegas, NV, USA'; /* 1 second */

select * from users where location = 'Las Vegas, NV, USA' order by reputation desc limit 100; /* 2 seconds */

EXPLAIN(analyze, BUFFERS)
select * from users where location = 'Las Vegas, NV, USA' order by reputation desc limit 100; /* 2 seconds */



/* How to read a plan, intro */

/* Making it faster with indexes */
create index users_location on public.users using btree(location); /* takes 45 seconds, explain that we're literally making a copy of the table */


/* Review the new plan after index */
EXPLAIN(analyze, BUFFERS)
select * from users where location = 'Las Vegas, NV, USA' order by reputation desc limit 100; ; /* 2 seconds */



/* Teaching how to remove the sort */
create index users_location_reputation on public.users using btree(location, reputation);

EXPLAIN(analyze, BUFFERS)
select * from users where location = 'Las Vegas, NV, USA' order by reputation desc limit 100; /* 2 seconds */

/* Note that parallelism is gone
 * Note backward index scan
 * 
 * So, what are the drawbacks of the wider index?
 */

select * from check_indexes('public', 'users');

/* Introducing check_indexes to them for the first time
 * Index on location_reputation is physically larger than the one on just location
 * Reputation column has to be kept in sync with every update
 * Ideally, don't want to index "hot" columns because it causes more IO
 * Strike a balance between making selects faster vs making inserts/updates/deletes faster
 * Here, we can eliminate users_location because any query that needed just location can use location_reputation
 */

drop index users_location;

explain (analyze, buffers)
select * from users where location = 'Las Vegas, NV, USA';

/* Uses index on location_reputation
 * This way I only have 1 copy lying around instead of 2
 * You probably have this problem in your own environment - to find it:
 */
select * from check_indexes('public', null);







/* IF WE TRY TO TEACH USING JUST THE USERS TABLE: */


/* Back to our own indexes on users: */
select * from check_indexes('public', 'users');

explain(analyze, buffers)
select * from users where reputation = 12345;


/* Route A: it doesn't get used because it's the second column. Fix that by adding index on Reputation.
 * Route 2: it doesn't get used because the stats are wrong. Fix that by doing an analyze.
 * 			Then, point out that it can be even faster if reputation was the first column in the index.
 * 			Create another index on just reputation, and compare the plans.
 * Route III: Don't even bother trying to query the 2nd column of the index, and just move on to the next topic.
 */



explain(analyze, buffers)
select count(*) from users where reputation = 12345;

select * from users where reputation = 12345;

explain(analyze, buffers)
select reputation, location from users where reputation = 12345;

explain(analyze, buffers)
select reputation, location, displayname, id from users where reputation = 12345;

/* Why is it avoiding the index? Because the estimates were wrong.
 * Fix the estimates:
 */
analyze public.users;

/* Rerun the query: */
explain(analyze, buffers)
select * from users where reputation = 12345;




EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select * from users where reputation = 12345;

/* This shows as an index scan, but that's not really true.
 * We're outputting more than what's on the index.
 * The base table had to be hit to gather that additional data.
 */
 






/* IF WE TRY TO TEACH JOINS: */
select * 
	from users u
	join posts p on u.id = p.owneruserid
where u.location = 'Las Vegas, NV, USA'
order by p.score desc 
limit 10;

/* Will this be fast? Why? Which table will Postgres look at first? */
select * from check_indexes('public', 'posts');

/* Note that we need to already have an index on posts.owneruserid
 * before the class starts to avoid waiting 2 minutes to create it.
 *  */


EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select * 
	from users u
	join posts p on u.id = p.owneruserid
where u.location = 'Las Vegas, NV, USA'
order by p.score desc 
limit 10;


/* Depending on the starting point of the database's stats on posts,
 * the query may or may not use the index on posts_owneruserid.
 * I need to get this demo to be idempotent, so later I need to 
 * go through and make it that way.
 * 
 * In the meantime, I can say that if it doesn't use the index,
 * talk about ANALYZE to update the stats.
 */
analyze public.users;



/* Reading the query plan:
 * Bottom up, left to right
 * Index scan doesn't mean we read the whole thing
 */


/* It processed the users table first.
 * 
 * Is that because of the way we wrote the query? 
 */
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select * 
	from users u
	join posts p on u.id = p.owneruserid
where u.location = 'Las Vegas, NV, USA'
order by p.score desc 
limit 10;




/* Let's rewrite it with posts first in the joins: 
 * */
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select * 
	from posts p
	join users u on p.owneruserid = u.id
where u.location = 'Las Vegas, NV, USA'
order by p.score desc 
limit 10;

/* PGSQL is a declarative language.
 * You're declaring the shape of your result set first,
 * but Postgres can rewrite your query.
 */


/* Different parameters can cause different index usage & plan shapes: */

EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select * 
	from users u
	join posts p on u.id = p.owneruserid
where u.location = 'China'
order by p.score desc 
limit 10;


