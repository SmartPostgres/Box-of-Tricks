drop table if exists public.users cascade;

CREATE TABLE public.users (
    user_id SERIAL PRIMARY KEY, /* Creates a row in pg_class */
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL, /* Creates a row in pg_class */
    reputation INTEGER DEFAULT 0,
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_access_date TIMESTAMPTZ,
    location VARCHAR(255),
    about_me TEXT,
    about_me_tsvector TSVECTOR,
    website_url VARCHAR(255),
    profile_image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    "space space" VARCHAR,
    "1" INTEGER,
    " " VARCHAR,
    "." VARCHAR,
    "," VARCHAR,
    """" VARCHAR,
    "ヅ" VARCHAR
);

-- Set the autovacuum settings
alter table public.users set (autovacuum_enabled = false);

ALTER TABLE public.users 
    SET (autovacuum_vacuum_threshold = 10000,  -- Minimum number of dead tuples before vacuuming starts
         autovacuum_vacuum_scale_factor = 0.0,  -- Percentage of the table size that triggers a vacuum
         autovacuum_analyze_threshold = 500,  -- Minimum number of tuple changes before analyze starts
         autovacuum_analyze_scale_factor = 0.02,  -- Percentage of the table size that triggers an analyze
         autovacuum_vacuum_cost_delay = 20,  -- Delay in milliseconds between vacuum operations
         autovacuum_vacuum_cost_limit = 2000,  -- Cost limit for vacuuming before taking a delay
         autovacuum_freeze_max_age = 200000000,  -- Maximum age of tuples before forcing a vacuum to prevent transaction wraparound
         autovacuum_multixact_freeze_max_age = 400000000);  -- Maximum age of multixact before vacuum forces wraparound prevention


-- Optionally, reset the settings back to the default values:
-- ALTER TABLE sales RESET (autovacuum_enabled, autovacuum_vacuum_threshold, autovacuum_vacuum_scale_factor, 
--                          autovacuum_analyze_threshold, autovacuum_analyze_scale_factor, autovacuum_vacuum_cost_delay, 
--                          autovacuum_vacuum_cost_limit, autovacuum_freeze_max_age, autovacuum_multixact_freeze_max_age);

         
         
         

INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,50000);

/*
INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'Jorriss', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Orlando, FL', 'A non-fictional character', 'A non-fictional character',
	'https://www.postgresql.org', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10);
*/

CREATE INDEX idx_users_display_name ON public.users (display_name);
CREATE INDEX idx_users_email_hash ON public.users USING hash (email);
CREATE INDEX idx_users_about_me_gin ON public.users USING gin (to_tsvector('english', about_me));
CREATE INDEX idx_users_about_me_tsvector_gist ON public.users USING gist (about_me_tsvector);
CREATE INDEX idx_users_location_spgist ON public.users USING spgist (location);
CREATE INDEX idx_users_creation_date_brin ON public.users USING brin (creation_date);

create index filtered_empty on public.users(display_name)
	where 1 = 0;

create index filtered_some_rows on public.users(display_name)
	where display_name = 'Jorriss';



create index "space space" on public.users ("space space");
create index "1" on public.users("1");
create index " " on public.users(" ");
create index "." on public.users(".");
create index "," on public.users(",");
create index """" on public.users("""");
create index "ヅ" on public.users("ヅ");

/* Adding more rows after the indexes have been created
 * so we can test for accurate row counts in filtered index stats. */
INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,50000);


delete from public.users;




drop view if exists public.vw_users;

CREATE VIEW public.vw_users AS
SELECT 
    user_id, 
    display_name, 
    reputation, 
    location, 
    creation_date
FROM 
    public.users;

drop view if exists public.vw_users_hours_since_last_access;

CREATE MATERIALIZED VIEW public.vw_users_hours_since_last_access AS
SELECT 
    user_id, 
    display_name, 
    reputation, 
    location, 
    creation_date, 
    last_access_date,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - last_access_date)) / 3600 AS hours_since_last_access
FROM 
    public.users;

   
refresh materialized view public.vw_users_hours_since_last_access;


/* Insert more rows so that the materialized view is out of date: */
INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10000);





drop sequence if exists public.user_sequence;

CREATE SEQUENCE public.user_sequence
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


   
drop table if exists public.toast_big_data cascade;
   
CREATE TABLE public.toast_big_data (
    toast_big_data_id SERIAL PRIMARY KEY, /* Creates a row in pg_class */
    giant_value_1 VARCHAR,
    giant_value_2 VARCHAR
);

INSERT INTO public.toast_big_data
(giant_value_1, giant_value_2)
select REPEAT('Malkovich ', 10000), REPEAT('Malkovich ', 10000)
from generate_series(1,10000);   
      



drop table if exists public.bad_estimates cascade;


CREATE TABLE public.bad_estimates (
    user_id SERIAL PRIMARY KEY, /* Creates a row in pg_class */
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL, /* Creates a row in pg_class */
    reputation INTEGER DEFAULT 0,
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_access_date TIMESTAMPTZ,
    location VARCHAR(255),
    about_me TEXT,
    about_me_tsvector TSVECTOR,
    website_url VARCHAR(255),
    profile_image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    "space space" VARCHAR,
    "1" INTEGER,
    " " VARCHAR,
    "." VARCHAR,
    "," VARCHAR,
    """" VARCHAR,
    "ヅ" VARCHAR
);

INSERT INTO public.bad_estimates
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10000);

INSERT INTO public.bad_estimates
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'Jorriss', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Orlando, FL', 'A non-fictional character', 'A non-fictional character',
	'https://www.postgresql.org', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10);

   
alter table public.bad_estimates set (autovacuum_enabled = false);

INSERT INTO public.bad_estimates
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,100000);

INSERT INTO public.bad_estimates
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'Jorriss', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Orlando, FL', 'A non-fictional character', 'A non-fictional character',
	'https://www.postgresql.org', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,1000);






-- Step 1: Create the parent table
drop table if exists public.users_partitioned cascade;

CREATE TABLE public.users_partitioned (
    id SERIAL,
    displayname VARCHAR(100),
    location VARCHAR(100),
    reputation INTEGER,
    creationdate DATE,
    lastaccessdate DATE, 
    PRIMARY KEY (id, creationdate)  -- Include creationdate in the primary key

) PARTITION BY RANGE (creationdate);

-- Step 2: Create partitions by year
CREATE TABLE public.users_partitioned_2018 PARTITION OF users_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE public.users_partitioned_2019 PARTITION OF users_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

CREATE TABLE public.users_partitioned_2020 PARTITION OF users_partitioned
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE public.users_partitioned_2021 PARTITION OF users_partitioned
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE public.users_partitioned_2022 PARTITION OF users_partitioned
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE public.users_partitioned_2023 PARTITION OF users_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- Step 3: Add indexes on DisplayName and Location
CREATE INDEX idx_users_displayname ON public.users_partitioned USING btree (displayname);
CREATE INDEX idx_users_location ON public.users_partitioned USING btree (location);

-- Step 4: Insert random data
DO $$
DECLARE
    i INT;
    creation_date DATE;
BEGIN
    FOR i IN 1..100000 LOOP
        -- Generate a random creation date between 2019 and 2022
        creation_date := DATE '2019-01-01' + (random() * (DATE '2023-01-01' - DATE '2019-01-01'))::INT;
        
        INSERT INTO public.users_partitioned (displayname, location, reputation, creationdate, lastaccessdate)
        VALUES (
            'User' || i,  -- Random display name
            'Location' || (random() * 100)::INT,  -- Random location
            (random() * 10000)::INT,  -- Random reputation
            creation_date,
            creation_date + (random() * 365)::INT  -- Random last access date within a year
        );
    END LOOP;
END $$;





-- Step 1: Create the parent table
drop table if exists public.users_partitioned_noindexes cascade;

CREATE TABLE public.users_partitioned_noindexes (
    id SERIAL,
    displayname VARCHAR(100),
    location VARCHAR(100),
    reputation INTEGER,
    creationdate DATE,
    lastaccessdate DATE
) PARTITION BY RANGE (creationdate);

-- Step 2: Create partitions by year
CREATE TABLE public.users_partitioned_noindexes_2018 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE public.users_partitioned_noindexes_2019 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

CREATE TABLE public.users_partitioned_noindexes_2020 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE public.users_partitioned_noindexes_2021 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE public.users_partitioned_noindexes_2022 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE public.users_partitioned_noindexes_2023 PARTITION OF users_partitioned_noindexes
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- Step 3: Collect underpants

-- Step 4: Insert random data
DO $$
DECLARE
    i INT;
    creation_date DATE;
BEGIN
    FOR i IN 1..100000 LOOP
        -- Generate a random creation date between 2019 and 2022
        creation_date := DATE '2019-01-01' + (random() * (DATE '2023-01-01' - DATE '2019-01-01'))::INT;
        
        INSERT INTO public.users_partitioned_noindexes (displayname, location, reputation, creationdate, lastaccessdate)
        VALUES (
            'User' || i,  -- Random display name
            'Location' || (random() * 100)::INT,  -- Random location
            (random() * 10000)::INT,  -- Random reputation
            creation_date,
            creation_date + (random() * 365)::INT  -- Random last access date within a year
        );
    END LOOP;
END $$;








drop schema if exists duplicate CASCADE;

create schema duplicate;

CREATE TABLE duplicate.users (
    user_id SERIAL PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    reputation INTEGER DEFAULT 0,
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_access_date TIMESTAMPTZ,
    location VARCHAR(255),
    about_me TEXT,
    about_me_tsvector TSVECTOR,
    website_url VARCHAR(255),
    profile_image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    "space space" VARCHAR,
    "1" INTEGER,
    " " VARCHAR,
    "." VARCHAR,
    "," VARCHAR,
    """" VARCHAR,
    "ヅ" VARCHAR
);

INSERT INTO duplicate.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10000);

INSERT INTO duplicate.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'Jorriss', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Orlando, FL', 'A non-fictional character', 'A non-fictional character',
	'https://www.postgresql.org', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10);

CREATE INDEX idx_users_display_name ON duplicate.users (display_name);
CREATE INDEX idx_users_email_hash ON duplicate.users USING hash (email);
CREATE INDEX idx_users_about_me_gin ON duplicate.users USING gin (to_tsvector('english', about_me));
CREATE INDEX idx_users_about_me_tsvector_gist ON duplicate.users USING gist (about_me_tsvector);
CREATE INDEX idx_users_location_spgist ON duplicate.users USING spgist (location);
CREATE INDEX idx_users_creation_date_brin ON duplicate.users USING brin (creation_date);

create index filtered_empty on duplicate.users(display_name)
	where 1 = 0;

create index filtered_some_rows on duplicate.users(display_name)
	where display_name = 'Jorriss';

create index "space space" on duplicate.users ("space space");
create index "1" on duplicate.users("1");
create index " " on duplicate.users(" ");
create index "." on duplicate.users(".");
create index "," on duplicate.users(",");
create index """" on duplicate.users("""");
create index "ヅ" on duplicate.users("ヅ");

CREATE VIEW duplicate.vw_users AS
SELECT 
    user_id, 
    display_name, 
    reputation, 
    location, 
    creation_date
FROM 
    duplicate.users;


CREATE MATERIALIZED VIEW duplicate.vw_users_hours_since_last_access AS
SELECT 
    user_id, 
    display_name, 
    reputation, 
    location, 
    creation_date, 
    last_access_date,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - last_access_date)) / 3600 AS hours_since_last_access
FROM 
    duplicate.users;
refresh materialized view duplicate.vw_users_hours_since_last_access;
   
CREATE SEQUENCE duplicate.user_sequence
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

 drop table if exists duplicate.toast_big_data cascade;
   
CREATE TABLE duplicate.toast_big_data (
    toast_big_data_id SERIAL PRIMARY KEY, /* Creates a row in pg_class */
    giant_value_1 VARCHAR,
    giant_value_2 VARCHAR
);

INSERT INTO duplicate.toast_big_data
(giant_value_1, giant_value_2)
select REPEAT('Malkovich ', 10000), REPEAT('Malkovich ', 10000)
from generate_series(1,10000);   
      



drop schema if exists bad_names cascade;

create schema bad_names;

CREATE TABLE bad_names."space space " ("space space" SERIAL PRIMARY KEY);
CREATE TABLE bad_names."1" ("1" SERIAL PRIMARY KEY);
CREATE TABLE bad_names." " (" " SERIAL PRIMARY KEY);
CREATE TABLE bad_names."." ("." SERIAL PRIMARY KEY);
CREATE TABLE bad_names."," ("," SERIAL PRIMARY KEY);
CREATE TABLE bad_names."""" ("""" SERIAL PRIMARY KEY);
CREATE TABLE bad_names."ヅ" ("ヅ" SERIAL PRIMARY KEY);
CREATE TABLE bad_names."'" ("'" SERIAL PRIMARY KEY);

