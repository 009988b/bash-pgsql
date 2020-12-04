begin;
drop table if exists vehicles;
drop view if exists makemodel;
drop table if exists models;
drop table if exists user_transmissions;
drop table if exists user_engines;
drop table if exists users;
drop table if exists models;
drop table if exists engines;
drop table if exists transmissions;
drop table if exists makes;
commit;

begin;
create table users(
	id serial primary key,
	username text not null,
	password text not null,
	email text not null unique
);
commit;

begin;
create table makes(
	id serial primary key,
	name text unique,
	description text,
	logo_href text
);
commit;

begin;
create table engines(
	id serial primary key,
	makeid int,
	name text,
	family text,
	displ numeric,
	cyls numeric,
	bore numeric,
	stroke numeric,
	compr numeric,
	hp int,
	tq int,
	foreign key (makeid) references makes(id),
	unique (makeid,name)
);
commit;

begin;
create table transmissions(
	id serial primary key,
	makeid int,
	name text,
	description text,
	ratios int,
	img_href text,
	type text,
	foreign key (makeid) references makes(id),
	unique (makeid, name)
);
commit;


begin;
create table user_transmissions(
	id serial primary key,
	ownerid int,
	base_trans_id int,
	mods text,
	img_href text,
	foreign key (ownerid) references users(id),
	foreign key (base_trans_id) references transmissions(id)
);
commit;


begin;
create table user_engines(
	id serial primary key,
	ownerid int,
	base_engine_id int,
	bore numeric,
	stroke numeric,
	compr numeric,
	nickname text,
	hp int,
	tq int,
	mods text,
	img_href text,
	foreign key (ownerid) references users(id),
	foreign key (base_engine_id) references engines(id)
);
commit;

begin;
create table models(
	id serial primary key,
	makeid int,
	name text,
	engine int,
	trans int,
	description text,
	foreign key (makeid) references makes(id),
	foreign key (engine) references engines(id),
	foreign key (trans) references transmissions(id),
	unique (makeid,name)
);
commit;

begin;
create table vehicles(
	id serial primary key,
	ownerid int,
	modelid int,
	custom_trans int,
	custom_eng int,
	mods text,
	description text,
	miles text,
	fuel_type text,
	img_href text,
	year int,
	likes int,
	clowns int,
	foreign key (ownerid) references users(id),
	foreign key (modelid) references models(id),
	foreign key (custom_trans) references user_transmissions(id),
	foreign key (custom_eng) references user_engines(id)
);
commit;

-- view of every model name and their respective makename
begin;
create view makemodel as
	(select name from makes where id = models.makeid) "make", name "model"  from models;
commit;

-- this function gets make from model id
begin;
create or replace function make_from_modelid(modelid int)
returns text
language plpgsql
as
$$
declare
	makename text;
	makeid int;
begin
	select models.makeid into makeid from models where id = modelid;
	select makes.name from makes into makename where id = makeid;
	return makename;
end;
$$;
commit;