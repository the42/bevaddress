-- Copyright Johann Höchtl 2016 https://github.com/the42/bevaddress-dataload
--
-- Pipe this script through psql with an active connection
-- to your PostgreSQL database server using this command line:
--
--    psql -h HOST -p PORT -d DABASE -U username -W password -f create.sql
--
-- This command has to be called in the directory in which the files from
-- http://www.bev.gv.at/portal/page?_pageid=713,2601271&_dad=portal&_schema=PORTAL
-- got unzipped.

SET client_min_messages TO WARNING;

DROP TABLE IF EXISTS GEBAEUDE_FUNKTION;
CREATE TABLE GEBAEUDE_FUNKTION (
  ADRCD TEXT,
  SUBCD TEXT,
  OBJEKTNUMMER TEXT,
  OBJFUNKTKENNZIFFER TEXT
);

\copy GEBAEUDE_FUNKTION(ADRCD, SUBCD, OBJEKTNUMMER, OBJFUNKTKENNZIFFER) FROM 'GEBAEUDE_FUNKTION.csv' (FORMAT csv, HEADER true, DELIMITER ';')

DROP TABLE IF EXISTS GEBAEUDE;
CREATE TABLE GEBAEUDE (
  ADRCD TEXT,
  SUBCD TEXT,
  OBJEKTNUMMER TEXT,
  HAUPTADRESSE SMALLINT,
  HAUSNRVERBINDUNG2 TEXT,
  HAUSNRZAHL3 INTEGER,
  HAUSNRBUCHSTABE3 TEXT,
  HAUSNRVERBINDUNG3 TEXT,
  HAUSNRZAHL4 INTEGER,
  HAUSNRBUCHSTABE4 TEXT,
  HAUSNRGEBAEUDEBEZ TEXT,
  RW DOUBLE PRECISION,
  HW DOUBLE PRECISION,
  EPSG INTEGER,
  QUELLADRESSE TEXT,
  BESTIMMUNGSART TEXT,
  EIGENSCHAFT TEXT
);

\copy GEBAEUDE(ADRCD, SUBCD, OBJEKTNUMMER, HAUPTADRESSE, HAUSNRVERBINDUNG2, HAUSNRZAHL3, HAUSNRBUCHSTABE3, HAUSNRVERBINDUNG3, HAUSNRZAHL4, HAUSNRBUCHSTABE4, HAUSNRGEBAEUDEBEZ, RW, HW, EPSG, QUELLADRESSE, BESTIMMUNGSART, EIGENSCHAFT) FROM 'GEBAEUDE.csv' (FORMAT csv, HEADER true, DELIMITER ';')

-- There is an issue with the epsg codes and the translation of BEV address data from the SRIDs
-- 31254, 31255, 31256. The contents of spatial_ref_sys.proj4text is used by PostGIS-Function
-- ST_Transform to project from one coordinate system into another.
-- In order to greatly increase accuracy, perform the following updates:
-- cf. http://gis.stackexchange.com/questions/203982/st-transform-is-way-too-inexact

UPDATE spatial_ref_sys SET proj4text = '+proj=tmerc +lat_0=0 +lon_0=10.33333333333333 +k=1 +x_0=0 +y_0=-5000000 +ellps=bessel +towgs84=577.326,90.129,463.919,5.137,1.474,5.297,2.4232 +units=m +no_defs' WHERE srid = 31254;
UPDATE spatial_ref_sys SET proj4text = '+proj=tmerc +lat_0=0 +lon_0=13.33333333333333 +k=1 +x_0=0 +y_0=-5000000 +ellps=bessel +towgs84=577.326,90.129,463.919,5.137,1.474,5.297,2.4232 +units=m +no_defs' WHERE srid = 31255;
UPDATE spatial_ref_sys SET proj4text = '+proj=tmerc +lat_0=0 +lon_0=16.33333333333333 +k=1 +x_0=0 +y_0=-5000000 +ellps=bessel +towgs84=577.326,90.129,463.919,5.137,1.474,5.297,2.4232 +units=m +no_defs' WHERE srid = 31256;

-- add an additional column to the table GEBAEUDE to keep the original RW, HW in the given EPSG code
ALTER TABLE GEBAEUDE DROP COLUMN IF EXISTS MGIAUSTRIAGK;
ALTER TABLE GEBAEUDE ADD COLUMN MGIAUSTRIAGK geometry(POINT);
-- insert the HW and RW into this newly created column
UPDATE GEBAEUDE SET MGIAUSTRIAGK = ST_SetSRID(ST_MakePoint(RW, HW), epsg);

-- add an additional column to the table GEBAEUDE to keep coordinates in lat / long in geometric units
ALTER TABLE GEBAEUDE DROP COLUMN IF EXISTS LATLONG;
ALTER TABLE GEBAEUDE ADD COLUMN LATLONG geometry(POINT);
UPDATE GEBAEUDE SET LATLONG = ST_Transform(MGIAUSTRIAGK, 4326);
-- add an additional column to the table GEBAEUDE to keep coordinates in lat / long in geography units for distance measures
ALTER TABLE GEBAEUDE DROP COLUMN IF EXISTS LATLONG_G;
ALTER TABLE GEBAEUDE ADD COLUMN LATLONG_G geography(POINT);
UPDATE GEBAEUDE SET LATLONG_G = LATLONG::geography;


DROP TABLE IF EXISTS ADRESSE_GST;
CREATE TABLE ADRESSE_GST (
  ADRCD TEXT,
  KGNR TEXT,
  GSTNR TEXT,
  LFDNR integer
);

\copy ADRESSE_GST(ADRCD, KGNR, GSTNR, LFDNR) FROM 'ADRESSE_GST.csv' (FORMAT csv, HEADER true, DELIMITER ';')

DROP TABLE IF EXISTS ADRESSE;
CREATE TABLE ADRESSE (
  ADRCD TEXT,
  GKZ TEXT,
  OKZ TEXT,
  PLZ TEXT,
  SKZ TEXT,
  ZAEHLSPRENGEL TEXT,
  HAUSNRTEXT TEXT,
  HAUSNRZAHL1 INTEGER,
  HAUSNRBUCHSTABE1 TEXT,
  HAUSNRVERBINDUNG1 TEXT,
  HAUSNRZAHL2 INTEGER,
  HAUSNRBUCHSTABE2 TEXT,
  HAUSNRBEREICH TEXT,
  GNRADRESSE SMALLINT,
  HOFNAME TEXT,
  RW DOUBLE PRECISION,
  HW DOUBLE PRECISION,
  EPSG INTEGER,
  QUELLADRESSE TEXT,
  BESTIMMUNGSART TEXT
);

\copy ADRESSE(ADRCD, GKZ, OKZ, PLZ, SKZ, ZAEHLSPRENGEL, HAUSNRTEXT, HAUSNRZAHL1, HAUSNRBUCHSTABE1, HAUSNRVERBINDUNG1, HAUSNRZAHL2, HAUSNRBUCHSTABE2, HAUSNRBEREICH, GNRADRESSE,   HOFNAME, RW, HW, EPSG, QUELLADRESSE, BESTIMMUNGSART) FROM 'ADRESSE.csv' (FORMAT csv, HEADER true, DELIMITER ';')

-- add an additional column to the table ADRESSE to keep the original RW, HW in the given EPSG code
ALTER TABLE ADRESSE DROP COLUMN IF EXISTS MGIAUSTRIAGK;
ALTER TABLE ADRESSE ADD COLUMN MGIAUSTRIAGK geometry(POINT);
-- insert the HW and RW into this newly created column
UPDATE ADRESSE SET MGIAUSTRIAGK = ST_SetSRID(ST_MakePoint(RW, HW), epsg);

-- add an additional column to the table ADRESSE to keep coordinates in lat / long
ALTER TABLE ADRESSE DROP COLUMN IF EXISTS LATLONG;
ALTER TABLE ADRESSE ADD COLUMN LATLONG geometry(POINT);
UPDATE ADRESSE SET LATLONG = ST_Transform(MGIAUSTRIAGK, 4326);
-- add an additional column to the table ADRESSE to keep coordinates in lat / long in geography units for distance measures
ALTER TABLE ADRESSE DROP COLUMN IF EXISTS LATLONG_G;
ALTER TABLE ADRESSE ADD COLUMN LATLONG_G geography(POINT);
UPDATE ADRESSE SET LATLONG_G = LATLONG::geography;

DROP TABLE IF EXISTS STRASSE;
CREATE TABLE STRASSE (
  SKZ TEXT,
  STRASSENNAME TEXT,
  STRASSENNAMENZUSATZ TEXT,
  SZUSADRBEST SMALLINT,
  GKZ TEXT
);

\copy STRASSE(SKZ, STRASSENNAME, STRASSENNAMENZUSATZ, SZUSADRBEST, GKZ) FROM 'STRASSE.csv' (FORMAT csv, HEADER true, DELIMITER ';')

DROP TABLE IF EXISTS ZAEHLSPRENGEL;
CREATE TABLE ZAEHLSPRENGEL (
  GKZ TEXT,
  ZAEHLSPRENGEL TEXT,
  ZAEHLSPRENGELNAME TEXT
);

\copy ZAEHLSPRENGEL(GKZ, ZAEHLSPRENGEL, ZAEHLSPRENGELNAME) FROM 'ZAEHLSPRENGEL.csv' (FORMAT csv, HEADER true, DELIMITER ';')

DROP TABLE IF EXISTS ORTSCHAFT;
CREATE TABLE ORTSCHAFT (
  GKZ TEXT,
  OKZ TEXT,
  ORTSNAME TEXT
);

\copy ORTSCHAFT(GKZ, OKZ, ORTSNAME) FROM 'ORTSCHAFT.csv' (FORMAT csv, HEADER true, DELIMITER ';')

DROP TABLE IF EXISTS GEMEINDE;
CREATE TABLE GEMEINDE (
  GKZ TEXT,
  GEMEINDENAME TEXT
);

\copy GEMEINDE(GKZ, GEMEINDENAME) FROM 'GEMEINDE.csv' (FORMAT csv, HEADER true, DELIMITER ';')

-- Add the Bundesland as we will use it in constraints
ALTER TABLE GEMEINDE DROP COLUMN IF EXISTS BLD;
ALTER TABLE GEMEINDE ADD COLUMN BLD SMALLINT;
UPDATE GEMEINDE SET BLD = left(GKZ, 1)::SMALLINT WHERE BLD IS NULL;
-- Info from https://de.wikipedia.org/wiki/ISO_3166-2:AT
-- Burgenland Burgenland 	AT-1
-- Kärnten Kärnten 	AT-2
-- Niederösterreich Niederösterreich 	AT-3
-- Oberösterreich Oberösterreich 	AT-4
-- Land Salzburg Salzburg 	AT-5
-- Steiermark Steiermark 	AT-6
-- Tirol (Bundesland) Tirol 	AT-7
-- Vorarlberg Vorarlberg 	AT-8
-- Wien Wien 	AT-9


-- now check / add the constraints as they are advertised in the description BEV_S_AD_Adresse_Relationale_Tabellen-Stichtagsdaten-CSV_V1.0.pdf
ALTER TABLE GEMEINDE DROP CONSTRAINT IF EXISTS GEMEINDE_PK;
ALTER TABLE GEMEINDE ADD CONSTRAINT GEMEINDE_PK PRIMARY KEY(GKZ);

ALTER TABLE ORTSCHAFT DROP CONSTRAINT IF EXISTS ORTSCHAFT_PK;
ALTER TABLE ORTSCHAFT ADD CONSTRAINT ORTSCHAFT_PK PRIMARY KEY(OKZ);

ALTER TABLE STRASSE DROP CONSTRAINT IF EXISTS STRASSE_PK;
ALTER TABLE STRASSE ADD CONSTRAINT STRASSE_PK PRIMARY KEY(SKZ);

ALTER TABLE ZAEHLSPRENGEL DROP CONSTRAINT IF EXISTS ZAEHLSPRENGEL_PK;
ALTER TABLE ZAEHLSPRENGEL ADD CONSTRAINT ZAEHLSPRENGEL_PK PRIMARY KEY(GKZ, ZAEHLSPRENGEL);

ALTER TABLE ADRESSE DROP CONSTRAINT IF EXISTS ADRESSE_PK;
ALTER TABLE ADRESSE ADD CONSTRAINT ADRESSE_PK PRIMARY KEY(ADRCD);

ALTER TABLE GEBAEUDE DROP CONSTRAINT IF EXISTS GEBAEUDE_PK;
ALTER TABLE GEBAEUDE ADD CONSTRAINT GEBAEUDE_PK PRIMARY KEY(ADRCD, SUBCD);

-- as there is no ER diagram describing the relationship between the entities we guess from establishing foreign key relationships
ALTER TABLE ORTSCHAFT DROP CONSTRAINT IF EXISTS ORTSCHAFT_GKZ_FKEY;
ALTER TABLE ORTSCHAFT ADD CONSTRAINT ORTSCHAFT_GKZ_FKEY FOREIGN KEY (GKZ) REFERENCES GEMEINDE;

ALTER TABLE STRASSE DROP CONSTRAINT IF EXISTS STRASSE_GKZ_FKEY;
ALTER TABLE STRASSE ADD CONSTRAINT STRASSE_GKZ_FKEY FOREIGN KEY (GKZ) REFERENCES GEMEINDE;

ALTER TABLE ZAEHLSPRENGEL DROP CONSTRAINT IF EXISTS ZAEHLSPRENGEL_GKZ_FKEY;
ALTER TABLE ZAEHLSPRENGEL ADD CONSTRAINT ZAEHLSPRENGEL_GKZ_FKEY FOREIGN KEY (GKZ) REFERENCES GEMEINDE;

ALTER TABLE ADRESSE DROP CONSTRAINT IF EXISTS ADRESSE_GKZ_FKEY;
ALTER TABLE ADRESSE ADD CONSTRAINT ADRESSE_GKZ_FKEY FOREIGN KEY (GKZ) REFERENCES GEMEINDE;
ALTER TABLE ADRESSE DROP CONSTRAINT IF EXISTS ADRESSE_OKZ_FKEY;
ALTER TABLE ADRESSE ADD CONSTRAINT ADRESSE_OKZ_FKEY FOREIGN KEY (OKZ) REFERENCES ORTSCHAFT;
ALTER TABLE ADRESSE DROP CONSTRAINT IF EXISTS ADRESSE_SKZ_FKEY;
ALTER TABLE ADRESSE ADD CONSTRAINT ADRESSE_SKZ_FKEY FOREIGN KEY (SKZ) REFERENCES STRASSE;

--here we might have a problem, investigate:
--ALTER TABLE ADRESSE ADD CONSTRAINT ADRESSE_ZAEHLSPRENGEL_FKEY FOREIGN KEY (GKZ, ZAEHLSPRENGEL) REFERENCES ZAEHLSPRENGEL;
--ERROR:  insert or update on table "adresse" violates foreign key constraint "adresse_zaehlsprengel_fkey"
--DETAIL:  Key (gkz, zaehlsprengel)=(30201, ) is not present in table "zaehlsprengel".

ALTER TABLE ADRESSE_GST DROP CONSTRAINT IF EXISTS ADRESSE_GST_ADRCD_FKEY;
ALTER TABLE ADRESSE_GST ADD CONSTRAINT ADRESSE_GST_ADRCD_FKEY FOREIGN KEY (ADRCD) REFERENCES ADRESSE;

ALTER TABLE GEBAEUDE DROP CONSTRAINT IF EXISTS GEBAEUDE_ADRCD_FKEY;
ALTER TABLE GEBAEUDE ADD CONSTRAINT GEBAEUDE_ADRCD_FKEY FOREIGN KEY (ADRCD) REFERENCES ADRESSE;

ALTER TABLE GEBAEUDE_FUNKTION DROP CONSTRAINT IF EXISTS GEBAEUDE_FUNKTION_ADRCD_SUBCD_FKEY;
ALTER TABLE GEBAEUDE_FUNKTION ADD CONSTRAINT GEBAEUDE_FUNKTION_ADRCD_SUBCD_FKEY FOREIGN KEY (ADRCD, SUBCD) REFERENCES GEBAEUDE;



--Create idices to make querying fast
DROP INDEX IF EXISTS gemeinde_gemeindename;
CREATE INDEX gemeinde_gemeindename ON GEMEINDE(GEMEINDENAME);
DROP INDEX IF EXISTS gemeinde_bld;
CREATE INDEX gemeinde_bld ON GEMEINDE(BLD);

DROP INDEX IF EXISTS ortschaft_gkz;
CREATE INDEX ortschaft_gkz ON ORTSCHAFT(GKZ);
DROP INDEX IF EXISTS ortschaft_ortsname;
CREATE INDEX ortschaft_ortsname ON ORTSCHAFT(ORTSNAME);

DROP INDEX IF EXISTS strasse_strassenname;
CREATE INDEX strasse_strassenname ON STRASSE(STRASSENNAME);
DROP INDEX IF EXISTS strasse_gkz;
CREATE INDEX strasse_gkz ON STRASSE(GKZ);

DROP INDEX IF EXISTS adresse_gkz;
CREATE INDEX adresse_gkz ON ADRESSE(GKZ);
DROP INDEX IF EXISTS adresse_okz;
CREATE INDEX adresse_okz ON ADRESSE(OKZ);
DROP INDEX IF EXISTS adresse_plz;
CREATE INDEX adresse_plz ON ADRESSE(PLZ);
DROP INDEX IF EXISTS adresse_skz;
CREATE INDEX adresse_skz ON ADRESSE(SKZ);
DROP INDEX IF EXISTS adresse_hofname;
CREATE INDEX adresse_hofname ON ADRESSE(HOFNAME);
DROP INDEX IF EXISTS adresse_latlong;
CREATE INDEX adresse_latlong ON ADRESSE USING GIST(LATLONG);
DROP INDEX IF EXISTS adresse_latlong_g;
CREATE INDEX adresse_latlong_g ON ADRESSE USING GIST(LATLONG_G);


--- Prepare for full text search

--Add a custom dictionary to normalize abbreviations
ALTER TEXT SEARCH CONFIGURATION german ALTER MAPPING FOR host, uint WITH simple;
ALTER TEXT SEARCH CONFIGURATION german ALTER MAPPING FOR asciiword, word, asciihword, hword WITH german_stem;

DROP TEXT SEARCH DICTIONARY IF EXISTS bevaddress_syn;
CREATE TEXT SEARCH DICTIONARY bevaddress_syn (
    TEMPLATE = synonym,
    SYNONYMS = bevaddress
);

DROP TEXT SEARCH DICTIONARY IF EXISTS bevaddress_thes;
CREATE TEXT SEARCH DICTIONARY bevaddress_thes (
    TEMPLATE = thesaurus,
    DictFile = bevaddress,
    Dictionary = pg_catalog.german_stem
);
ALTER TEXT SEARCH CONFIGURATION german ALTER MAPPING FOR asciiword, host, word, asciihword, hword, uint WITH bevaddress_syn, bevaddress_thes, german_stem;

---Use the following to reset text search to default
--ALTER TEXT SEARCH CONFIGURATION german ALTER MAPPING FOR host, uint WITH simple;
--ALTER TEXT SEARCH CONFIGURATION german ALTER MAPPING FOR asciiword, word, asciihword, hword WITH german_stem;
--DROP  TEXT SEARCH DICTIONARY bevaddress_syn;
--DROP TEXT SEARCH DICTIONARY bevaddress_thes;


--Creata a specific table for FTS
DROP TABLE IF EXISTS ADDRITEMS;
CREATE TABLE ADDRITEMS AS
select plz, gemeindename, ortsname, strassenname, strassennamenzusatz, hausnrzahl1::text, hausnrtext, hausnrverbindung1, hofname, gemeinde.gkz, ortschaft.okz, strasse.skz, adresse.adrcd, bld
from adresse
inner join strasse
on adresse.skz = strasse.skz
and adresse.gkz = strasse.gkz
and adresse.gkz = strasse.gkz
inner join ortschaft
on adresse.okz = ortschaft.okz
and adresse.gkz = ortschaft.gkz
inner join gemeinde
on adresse.gkz = gemeinde.gkz;

DROP INDEX IF EXISTS ADDRITEMS_gkz;
CREATE INDEX ADDRITEMS_gkz ON ADDRITEMS(GKZ);
DROP INDEX IF EXISTS ADDRITEMS_okz;
CREATE INDEX ADDRITEMS_okz ON ADDRITEMS(OKZ);
DROP INDEX IF EXISTS ADDRITEMS_plz;
CREATE INDEX ADDRITEMS_plz ON ADDRITEMS(PLZ);
DROP INDEX IF EXISTS ADDRITEMS_skz;
CREATE INDEX ADDRITEMS_skz ON ADDRITEMS(SKZ);
DROP INDEX IF EXISTS ADDRITEMS_bld;
CREATE INDEX ADDRITEMS_bld ON ADDRITEMS(BLD);

ALTER TABLE ADDRITEMS DROP COLUMN IF EXISTS SEARCH;
ALTER TABLE ADDRITEMS ADD COLUMN SEARCH tsvector;
--Whenever changes are made to the dictionaries, this update has to be re-executed
--and the following index textsearch_idx re-created
UPDATE ADDRITEMS
  SET SEARCH =
    setweight(coalesce(plz,'')::tsvector, 'A')  || ' ' ||
    setweight(to_tsvector('german', coalesce(gemeindename,'')), 'B') || ' ' ||
    setweight(to_tsvector('german', coalesce(ortsname,'')), 'B') || ' ' ||
    setweight(to_tsvector('german', coalesce(strassenname,'')), 'C') || ' ' ||
    setweight(to_tsvector('german', coalesce(strassennamenzusatz,'')), 'D') || ' ' ||
    setweight(to_tsvector('german', coalesce(hausnrzahl1, '')), 'D') || ' ' ||
    setweight(to_tsvector('german', coalesce(hausnrtext,'')), 'D') || ' ' ||
    setweight(to_tsvector('german', coalesce(hausnrverbindung1,'')), 'D') || ' ' ||
    setweight(to_tsvector('german', coalesce(hofname,'')), 'D');

DROP INDEX IF EXISTS textsearch_idx;
CREATE INDEX textsearch_idx ON ADDRITEMS USING gin(SEARCH);
