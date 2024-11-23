SELECT * FROM PLAYER_SEASONS;


CREATE TYPE season_stats AS (
                season INTEGER,
				gp INTEGER,
				pts REAL,
				reb REAL,
				ast REAL
          
)

--Constructing a table that will contain all the fixed values as columns and
--the changing values as an array of type season_stats(created before)

CREATE TABLE players(

           player_name TEXT,
		   height TEXT,
		   college TEXT,
		   country TEXT,
		   draft_year TEXT,
		   draft_round TEXT,
		   draft_number TEXT,
		   season_stats season_stats[],
		   current_season INTEGER, --Will have the latest value of season
		   PRIMARY KEY(player_name,current_season)
)

--DROP TABLE players

SELECT MIN(season) FROM player_seasons;
--We see that 1996 is the min value

--------------------------------------------------------------------
--BUILDING THE CUMULATIVE TABLE DESIGN
--------------------------------------------------------------------
INSERT INTO players(
WITH yesterday AS(
--This can be considered the seed query,essentially returns no rows
        SELECT * FROM players
		WHERE current_season=1996--A year lesser than actual min

),
     today as(

	     SELECT * FROM player_seasons
		 WHERE season=1997

	 )

SELECT COALESCE(y.player_name,t.player_name) AS player_name,
       COALESCE(y.height,t.height) AS height,
	   COALESCE(y.college,t.college) AS college,
	   COALESCE(y.country,t.country) AS country,
	   COALESCE(y.draft_year,t.draft_year) AS draft_year,
	   COALESCE(y.draft_round,t.draft_round) AS draft_round,
	   COALESCE(y.draft_number,t.draft_number) AS draft_number,

--when there is no data in yesterday table,fill in with todays data   
	   CASE WHEN y.season_stats IS NULL
	   THEN ARRAY[ROW(
	            t.season ,
				t.gp ,
				t.pts ,
				t.reb ,
				t.ast 

	   )::season_stats]-- The :: will help in converting the Array into struct type season_stats that we declared above
	   WHEN t.season  IS NOT NULL
	   THEN
	        y.season_stats || 
	        ARRAY[ROW(
	            t.season ,
				t.gp ,
				t.pts ,
				t.reb ,
				t.ast 

	   )::season_stats] 
	   
	   ELSE y.season_stats
	   END AS season_stats,
	   COALESCE(t.season,y.current_season+1) AS current_season
	   


FROM yesterday y FULL OUTER JOIN today t
ON y.player_name=t.player_name)
--------------------------------------------------------------------
--Retrieving data from the Cumulative table
--------------------------------------------------------------------
SELECT * FROM PLAYERS;

WITH unnested AS(
--To get them into separate rows
SELECT player_name,UNNEST(season_stats) AS season_stats
FROM players
WHERE current_season=1997 
AND player_name='Anthony Mason')

--To explode futher into columns
SELECT player_name, (season_stats::season_stats).* 
FROM unnested
----------------------------------------------------------------------------------------------------------------------------------------
--The benefits
----------------------------------------------------------------------------------------------------------------------------------------
/*	•	Order Preservation: RLE compresses data without altering its order, making it highly compatible with sorted 
        datasets and queries that depend on order (e.g., range scans).
	•	Efficient Compression: It encodes consecutive repeated values as value-count pairs, achieving better
	    compression for sorted or repetitive data.
	•	Query Optimization: RLE improves query performance by reducing the amount of data to process, especially
	    in columnar databases with sorted or grouped columns.*/
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE players

CREATE TYPE scoring_class AS ENUM('star','good','average','bad');


CREATE TABLE players(

           player_name TEXT,
		   height TEXT,
		   college TEXT,
		   country TEXT,
		   draft_year TEXT,
		   draft_round TEXT,
		   draft_number TEXT,
		   season_stats season_stats[],
		   current_season INTEGER, --Will have the latest value of season
		   scoring_class scoring_class,
		   years_since_last_season INTEGER,
		   PRIMARY KEY(player_name,current_season)
)

INSERT INTO players(
WITH yesterday AS(
--This can be considered the seed query,essentially returns no rows
        SELECT * FROM players
		WHERE current_season=1999--A year lesser than actual min

),
     today as(

	     SELECT * FROM player_seasons
		 WHERE season=2000

	 )

SELECT COALESCE(y.player_name,t.player_name) AS player_name,
       COALESCE(y.height,t.height) AS height,
	   COALESCE(y.college,t.college) AS college,
	   COALESCE(y.country,t.country) AS country,
	   COALESCE(y.draft_year,t.draft_year) AS draft_year,
	   COALESCE(y.draft_round,t.draft_round) AS draft_round,
	   COALESCE(y.draft_number,t.draft_number) AS draft_number,

--when there is no data in yesterday table,fill in with todays data   
	   CASE WHEN y.season_stats IS NULL
	   THEN ARRAY[ROW(
	            t.season ,
				t.gp ,
				t.pts ,
				t.reb ,
				t.ast 

	   )::season_stats]-- The :: will help in converting the Array into struct type season_stats that we declared above
	   WHEN t.season  IS NOT NULL
	   THEN
	        y.season_stats || 
	        ARRAY[ROW(
	            t.season ,
				t.gp ,
				t.pts ,
				t.reb ,
				t.ast 

	   )::season_stats] 
	   
	   ELSE y.season_stats
	   END AS season_stats,
	   COALESCE(t.season,y.current_season+1) AS current_season,
	   CASE WHEN t.season IS NOT NULL THEN  --Active this season
	        CASE WHEN t.pts>20 THEN 'star'
			     WHEN t.pts>15 THEN 'good'
				 WHEN t.pts>10 THEN 'average'
				 ELSE 'bad'
			END::scoring_class
	        ELSE y.scoring_class
				 	
	   END AS scoring_class,
	   CASE WHEN t.season IS NOT NULL THEN 0
	        ELSE y.years_since_last_season+1
			END AS years_since_last_season
			
FROM yesterday y FULL OUTER JOIN today t
ON y.player_name=t.player_name

----------------------------------------------------------------------------------------------------------------------------------------
--Some Analytics query
----------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM players WHERE current_season=2000

--Who had the greatest improvement?
SELECT player_name,season_stats[1] AS first_season,
season_stas[CARDINALITY (season_stats)] AS latest_season
FROM players
WHERE current_season=2001

--OR comparing the imprvmnt by dividing the points btween last season and first season:
SELECT player_name,
(season_stats[CARDINALITY (season_stats)]::season_stats).pts/
CASE WHEN (season_stats[1]::season_stats).pts=0 THEN 1
     ELSE (season_stats[1]::season_stats).pts 
	 END AS improvement
FROM players
WHERE current_season=2000
--ORDER BY 2 DESC
