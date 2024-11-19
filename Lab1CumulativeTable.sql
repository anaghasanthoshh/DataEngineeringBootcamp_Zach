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
WITH yesterday AS(
--This can be considered the seed query,essentially null
        SELECT * FROM player_seasons
		WHERE season=1995--A year lesser than actual min

),
     today as(

	     SELECT * FROM player_seasons
		 WHERE season=1996

	 )

SELECT COALESCE(y.player_name,t.player_name) AS player_name,
       COALESCE(y.height,t.height) AS height,
	   COALESCE(y.college,t.college) AS college,
	   COALESCE(y.country,t.country) AS country,
	   COALESCE(y.draft_year,t.draft_year) AS draft_year,
	   COALESCE(y.draft_round,t.draft_round) AS draft_round,
	   COALESCE(y.draft_number,t.draft_number) AS draft_number,
	   
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
	   END AS season_stats
	   ELSE y.season_stats


FROM yesterday y FULL OUTER JOIN today t
ON y.player_name=t.player_name


