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

INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'John Malkovich', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Las Vegas, NV', 'A fictional character', 'A fictional character',
	'https://SmartPostgres.com', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10000);

INSERT INTO public.users
(display_name, email, reputation, creation_date, last_access_date, "location", about_me, about_me_tsvector, 
website_url, profile_image_url, "space space", "1", " ", ".", ",", """", "ヅ")
select 'Jorriss', uuid_in(md5(random()::text || random()::text)::cstring), 1, '2024-08-20', '2024-08-20', 'Orlando, FL', 'A non-fictional character', 'A non-fictional character',
	'https://www.postgresql.org', null, 'space space', '1', ' ', '.', ',', '"', 'ヅ'
from generate_series(1,10);


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
      

   