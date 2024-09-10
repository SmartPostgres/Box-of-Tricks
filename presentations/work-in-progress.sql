/* Prep work ahead of the class: */
create index posts_owneruserid on public.posts using btree(owneruserid);
create index posts_score_owneruserid on public.posts using btree(score, owneruserid);
delete users where id < 0; /* removing tag-based users, making the data easier to understand */
drop index users_creationdate;
drop index users_displayname;
drop index users_location_displayname;
drop index users_reputation;
drop index users_location;
drop index users_location_reputation;


/* Meet the Stack Overflow users table: */
select * from public.users limit 100;

select ctid, xmin, xmax, * 
from public.users 
order by ctid
limit 100;


/* Review sizes: */
select * from check_indexes('public', 'users');


/* The way it's stored on disk, shown in the first page of this PDF:
 * https://SmartPostgres.com/go/free
 */

/* Let's say I'm looking for the people near me: */
select * from users where location = 'Las Vegas, NV, USA';


/* Run that a few times, note ordering */


/* Find the highest ranking users: */
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;


/* Run it a few times. It's slow each time, takes a second or two,
 * even though the table's relatively small. 
 * 
 * To find out why, we can have Postgres explain it:
 */
explain 
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;



/* But that doesn't explain much. For much more details: */
explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;



/* For help, copy/paste that into: 
 * https://explain.dalibo.com 
 */


/* When you see "ordinary table", it's just a heap of rows
 * stored in random order.
 * 
 * If you query check_indexes and you don't see any indexes
 * that match the sort order you're looking for,
 * your queries are gonna be slow because we have to scan
 * the entire heap of data looking for stuff:
 * */
select * from check_indexes('public', 'users');



/* How to read a plan, intro */


/* If we run it several times, it still takes a second
 * or two every time. Postgres is caching the raw data,
 * but not the finished output of the query.
 */
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;


/* If we want it to be faster, we're going to have
 * to pre-sort the data in the way we need it.
 * 
 * Let's create a copy of the table sorted by
 * location so we can quickly find the Vegas folks:
 */
create index users_location on public.users (location); 

/* Build another PDF with just Location, CTID for first visualization
 * Don't visualize it yet with the PDF because the PDF uses the Reputation column */
/* Look at the table & index sizes now: */
select * from check_indexes('public', 'users');


/* The index on users_location is literally a copy of the table. */


/* Review the new plan after index */
explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;



/* We're still sorting the data.
 * We could remove that work too if we pre-sort
 * the data by location, then by reputation: */
create index users_location_reputation 
	on public.users (location, reputation);



explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;

/* Note backward index scan
 * 
 * So what's actually inside that index?
 */
select location, reputation, ctid
	from users
	order by location, reputation 
	limit 100;


/* ctid = Current Tuple ID
 * 
 * It's a Postgres system pointer:
 * 		First number: physical page
 * 		Second number: the number of the tuple on the page
 * 
 * As in: to find ctid 200,18,
 * Postgres would open page #200,
 * and jump to tuple #18.
 * 
 * This does have implications about how Postgres handles
 * updates and deletes of existing rows, but that's for
 * another class.
 */

/* Takeaways:
 * Focus on the operators:
 * 		Taking the most time
 * 		Going parallel across multiple cores (enough cores?)
 * 		Filtering the most (reading unnecessary rows)
 * 		Not yet: estimation problems
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

explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;



/* Uses index on location_reputation
 * This way I only have 1 copy lying around instead of 2
 * You probably have this problem in your own environment - to find it:
 */
select * from check_indexes('public', 'null');







/* IF WE TRY TO TEACH USING JUST THE USERS TABLE: */


/* Back to our own indexes on users: */
select * from check_indexes('public', 'users');


select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;

select * 
	from users 
	where location LIKE 'Las Vegas%' 
	order by reputation desc 
	limit 100;

explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location LIKE 'Las Vegas%' 
	order by reputation desc 
	limit 100;


/* Is that any better than a leading % sign? */
explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location LIKE 'Las Vegas%' 
	order by reputation desc 
	limit 100;

/* Takeaway: if you're doing string searches,
 * you probably don't want btree indexes.
 * Postgres has other types that are better suited.
 * 
 * Fixfix: link to types of indexes
 */


/* Let's look at our index again: */
select * from check_indexes('public', 'users');


/* Is this index really on reputation? */
select *
from users
order by reputation desc
limit 100;


/* You can tell by time that something's up. Read the plan: */
explain (analyze, buffers, costs, verbose, format json)
select *
from users
order by reputation desc
limit 100;


/* We read the whole table. The index on location_reputation
 * isn't sorted by reputation.
 * 
 * To see that, look at your PDF index on location_reputation,
 * and see what work it would take you to find the top 100
 * users by reputation desc. They're not sorted in order.
 * 
 * Takeaway: a composite (multi-column) index is most useful
 * when you're leveraging the sort order of the 1st column.
 */

/* What about targeted point queries on reputation?
 * Does the index help there?
 */
select * from users where reputation = 12345;


explain (analyze, buffers, costs, verbose, format json)
select * from users where reputation = 12345;



/* What about a more common reputation score? */
explain (analyze, buffers, costs, verbose, format json)
select * from users where reputation = 1;



/* Introduce the tipping point: where it makes sense to
 * use the index versus where it doesn't.
 * 
 * To explore the tipping point, let's sort reputations
 * to find the most common ones:
 */
select reputation, count(*) as folks
from users u 
group by reputation
order by count(*) desc 
limit 100;


/* Try about 50K rows: */
explain (analyze, buffers, costs, verbose, format json)
select * from users where reputation = 101;


/* Try about 100K rows: */
explain (analyze, buffers, costs, verbose, format json)
select * from users where reputation = 41;



/* Takeaways:
 * If you ask for tens of thousands of rows, the chance
 * that you'll leverage an index starts to drop, especially
 * if it's not the first column in the index.
 * 
 * If you find yourself bringing back >1K rows in a query,
 * it's time to ask bigger questions about why, and why
 * you're not using pagination to just grab 1K or less
 * rows at a time.
 * 
 * Let's try adding an index on reputation alone:
 */
create index users_reputation on users(reputation);


/* Try about 100K rows: */
explain (analyze, buffers, costs, verbose, format json)
select * from users where reputation = 41;


/* Even though our query is doing something ridiculous,
 * like bringing back 100K rows, we've at least given
 * Postgres an index to use, so the query goes faster.
 * 
 * Now we have a few indexes though:
 */

select * from check_indexes('public', 'users');


/* Takeaways:
 * You need enough indexes to make enough queries go
 * fast enough.
 * 
 * The more you add, though:
 * 		The more space you take up
 * 		The longer your backups & restores take
 * 		The slower your inserts/updates/deletes go
 * 
 * Generally speaking, if people aren't complaining
 * about the speed of inserts/updates/deletes, and
 * management isn't complaining about server cost,
 * then you can probably add more indexes (until
 * you can't.)
 */




/* Back to our index on location_reputation.
 * It's most useful if we're leveraging the sort
 * order on the first column, location, like this:
 */
explain (analyze, buffers, costs, verbose, format json)
select * 
	from users 
	where location = 'Las Vegas, NV, USA' 
	order by reputation desc 
	limit 100;


/* That query uses the index. Now, let's make
 * that query a little more complicated: let's
 * find the questions & answers created by my
 * Las Vegas friends, by joining to posts:
 */
with top_users as (
	select * 
		from users 
		where location = 'Las Vegas, NV, USA' 
		order by reputation desc 
		limit 100
)
select tu.displayname, p.score, p.title, p.creationdate, p.body
	from top_users tu
	join posts p on tu.id = p.owneruserid
order by p.score desc 
limit 100;

/* I've already added an index on posts.owneruserid
 * to support the joins.
 * 
 * Think of joins as a where clause. We're looking for
 * where p.owneruserid is in a list. */
select * from check_indexes('public', 'posts');




/* Read the plan left to right, bottom to top: */
explain (analyze, buffers, costs, verbose, format json)
with top_users as (
	select * 
		from users 
		where location = 'Las Vegas, NV, USA' 
		order by reputation desc 
		limit 100
)
select tu.displayname, p.score, p.title, p.creationdate, p.body
	from top_users tu
	join posts p on tu.id = p.owneruserid
order by p.score desc 
limit 100;




/* But what happens if we pick an UNusual location,
 * one where very talkative people live?
 */
explain (analyze, buffers, costs, verbose, format json)
with top_users as (
	select * 
		from users 
		where location = 'New York, United States' 
		order by reputation desc 
		limit 10
)
select tu.displayname, p.score, p.title, p.creationdate, p.body
	from top_users tu
	join posts p on tu.id = p.owneruserid
order by p.score desc 
limit 100;


/* Postgres underestimated how much these people talk,
 * and it ends up pulling back way more rows than it
 * estimated, which can lead to slower queries.
 * 
 * It IS using the index - the index is in the plan,
 * but because New Yorkers are so talkative, the
 * query is slow.
 * 
 * Takeaway: when reading plans, look for thumbs-down
 * bad estimates where Postgres didn't realize how
 * many rows were going to come back.
 */


/* Overall takeaways:
 * 
 * Ordinary table = heap, slow to scan when you're
 * looking for specific rows
 * 
 * Indexes = table pre-sorted the way you want,
 * with the columns you want.
 * 
 * Indexes are most useful when the first column's
 * sort order is helpful for your query.
 * 
 * More indexes, more problems: bigger database size,
 * slower backup/restore, slower insert/update/delete.
 * 
 * Use check_indexes to list your indexes and remove
 * narrower subsets.
 * 
 * Joins are like a where clause. Build indexes to
 * support the columns you frequently join on.
 * 
 * Copy/paste your explain plans to explain.dalibo.com,
 * then look for warning icons for the longest
 * running operators, especially parallel ones,
 * reading & filtering out most of the table.
*/
