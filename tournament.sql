-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.


-- Project2: tournament database sql commands
/* !!!!!!!! NOTES !!!!!!!!!
put functions and views that are used in other functions and views first
otherwise \i tournament.sql will not create the later functions or views
*/

DROP DATABASE IF EXISTS tournament;
-- drop the tournament database to create a new one
CREATE DATABASE tournament;
\c tournament

CREATE TABLE players(
-- create players table
	playerid	serial PRIMARY KEY,
	playername	text 
				NOT NULL 
				CHECK(playername <> '')
);

CREATE TABLE matches(
-- create matches table
	matchid serial PRIMARY KEY,
	matchwinner	integer REFERENCES players(playerid),
	matchloser	integer REFERENCES players(playerid),
	draw	boolean DEFAULT false
);

-- create tounament table
/*CREATE TABLE tournament(
	tourid serial PRIMARY KEY,
	tourname text
);*/
-- create playerTour table
/*CREATE TABLE playerTour(
	tourid serial PRIMARY KEY,
	playerid integer REFERENCES players (playerid)
);*/

-- create views and functions

CREATE OR REPLACE FUNCTION fbyeid()
-- returns the player 'BYE' playerid
	RETURNS integer
	AS
	$body$
		SELECT playerid
		FROM players
		WHERE playername = '_BYE_'
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION fOMW (p integer)
-- returns the OMW for player p
	RETURNS numeric
	AS
	$body$
		SELECT SUM(OMW) AS TOT_OMW FROM
			(SELECT COUNT(matchwinner) as OMW
			FROM matches
			WHERE matchwinner IN(
			SELECT matchwinner
			FROM matches
			WHERE matchloser=$1
			UNION
			SELECT matchloser
			FROM matches
			WHERE matchwinner = $1)
			GROUP BY matchwinner)
			AS oponent
	$body$
	LANGUAGE sql
;

CREATE  OR REPLACE FUNCTION fplayerOMW(p integer)
/* returns 0 if query returns null
lesson learn: use of IF THEN ELSE in function */
	RETURNS integer
	AS
	$body$
		BEGIN
			IF  fOMW($1) is NULL THEN RETURN 0;
			ELSE RETURN fOMW($1);
			END IF;
		END;
	$body$
	LANGUAGE plpgsql
;

CREATE OR REPLACE FUNCTION fmatches (p integer)
-- returns the number of matches played by player p
	RETURNS bigint
	AS
	$body$
		SELECT COUNT(*) AS totalMatches
		FROM(
			SELECT matchwinner FROM matches
			WHERE matchwinner = $1
			OR matchloser = $1
		) AS played
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE VIEW vmatchesPlayed AS
/*-- return list of tuple (player, matches)
lesson learnt: call fuction in a view
*/
	SELECT playerid, playername, COUNT(matchwinner) AS played
	FROM
	(SELECT playerid, playername
	FROM players WHERE playerid <> fbyeid()
	) AS playerlist
	LEFT JOIN matches ON
	playerid = matchwinner
	OR playerid = matchloser
	GROUP BY playername, playerid
;

CREATE OR REPLACE VIEW vmatchesWon AS
-- returns list of tuple (player, wins) 
	SELECT playerid, playername,
	COUNT(matches.matchwinner) AS wins
	FROM
	(SELECT playerid, playername
	FROM players WHERE playerid <> fbyeid()
	) AS playerlist
	LEFT OUTER JOIN matches
	ON matchwinner = playerid
	AND draw = false
	GROUP BY playerid, matchwinner, playername
	ORDER BY playerid
;

CREATE OR REPLACE VIEW vmatchesLost AS
-- returns list of tuple (player, losses) 
	SELECT playerid, playername,
	COUNT(matches.matchloser) AS losses
	FROM
	(SELECT playerid, playername
	FROM players WHERE playerid <> fbyeid()
	) AS playerlist
	LEFT OUTER JOIN matches
	ON matchloser = playerid
	--AND matchloser <> matchwinner
	AND draw = false
	GROUP BY playerid, matchloser, playername
	ORDER BY losses DESC
;

CREATE OR REPLACE VIEW vmatchesDraw AS
-- returns list of tuple (player, draws) 
	SELECT
		playerlist.playerid,
		playerlist.playername,
		COUNT(matches.draw) AS draws
	FROM(
		(SELECT playerid, playername
		FROM players 
		WHERE playerid <> fbyeid()
		) AS playerlist
		LEFT outer JOIN matches
		ON (matchwinner = playerid AND draw = true)
		OR (matchloser = playerid AND draw = true)
	)
	GROUP BY playerlist.playerid, playername
;

CREATE OR REPLACE VIEW vplayerstandings AS
/* returns player standings (playerid, playername, wins, matches, omw)
using vmatchesWon and vmatchesPlayed
lesson learnt: custom column, parametized function.. very powerfull!!!*/
	SELECT
		vmatchesWon.playerid,
		vmatchesWon.playername,
		wins,
		played,
		fplayeromw(vmatchesWon.playerid) as omw
	FROM vmatchesWon
	JOIN vmatchesPlayed
	ON vmatchesWon.playerid = vmatchesPlayed.playerid
	ORDER BY wins DESC, omw DESC
;

CREATE OR REPLACE VIEW vwinloss AS
/* returns (playerid, playername, wins, losses)
using: vmatchesWon and vmatchesLost
used by vplayerstandingsComplete */
	select
	vmatchesWon.playerid,
	vmatchesWon.playername,
	wins,
	losses
	from vmatchesWon
	left join vmatchesLost
	on vmatchesWon.playerid = vmatchesLost.playerid
	--order by wins desc
;

CREATE OR REPLACE VIEW vdrawplayed AS
/* returns (playerid, playername, draws, matches)
using: vmatchesDraw and vmatchesPlayed
used by vplayerstandingsComplete */
	select
	vmatchesDraw.playerid,
	vmatchesDraw.playername,
	draws,
	played
	from vmatchesDraw
	left outer join vmatchesPlayed
	on vmatchesDraw.playerid = vmatchesPlayed.playerid
	-- order by draws desc
;

CREATE OR REPLACE VIEW vomwbye AS
/* returns (playerid, playername, omw, bye)
using fplayeromw, 
used by vplayerstandingsComplete
lesson learn: JOIN techniques*/
	select * from
		(select playerid,
			playername,
			fplayeromw(playerid) as omw,
			pbye
			from players 
			left join 
				(select matchwinner,
					count(matchwinner) as pbye 
					from matches 
					where 
					matchloser = fbyeid() 
				group by matchwinner) as mbye
			on playerid = matchwinner) as omwbye
	where playerid <> fbyeid()
;

CREATE OR REPLACE VIEW vplayerstandingsComplete AS
/*-- returns (playerid, playername, wins losses, draws, matches)
-- uses views: vwinloss, vdrawplayed, vomwbye
lesson learnt: cascade JOIN's: very powerfull!!!
order on multiple colomns
pay attention to table aliases like complete1 
*/
	SELECT
		complete1.playerid, 
		complete1.playername,
		complete1.wins,
		complete1.losses,
		complete1.draws,
		omw,
		complete1.matches,
		pbye
	FROM
		(SELECT
			vwinloss.playerid,
			vwinloss.playername,
			wins,
			losses,
			draws,
			played as matches
		FROM vwinloss
		LEFT JOIN vdrawplayed
		ON vwinloss.playerid = vdrawplayed.playerid) AS complete1
		LEFT JOIN vomwbye
		ON complete1.playerid = vomwbye.playerid
	ORDER BY complete1.wins DESC, omw DESC, complete1.playerid
;

CREATE OR REPLACE FUNCTION fnextPlayerid()
-- returns next playerid in the sequence
RETURNS bigint
AS
$body$
	SELECT nextval('players_playerid_seq')
$body$
LANGUAGE sql
;

CREATE OR REPLACE VIEW vplayedBye AS
-- returns list of tuple (player, #bye) 
	SELECT playerid, playername,
	COUNT(matches.draw) AS BYE
	FROM
	(SELECT playerid, playername
	FROM players WHERE playerid <> fbyeid()
	) AS playerlist
	LEFT JOIN matches
	ON matchwinner = playerid
	AND matchloser = fbyeid()
	GROUP BY playerid, matchwinner, playername
	ORDER BY BYE DESC
;

CREATE OR REPLACE VIEW vnotPlayedBye AS
-- list of players who have no bye
	SELECT playerid
	FROM
		(SELECT playerid
		FROM players
		WHERE playerid <> fbyeid()
		) AS foo 
		LEFT JOIN matches
		ON matchwinner = playerid
		AND matchloser <> fbyeid()
;

CREATE OR REPLACE FUNCTION fcountPlayers()
-- returns the number of registered players
	RETURNS bigint
	AS
	$body$
		SELECT COUNT (*)
		FROM players
		WHERE playername <> '_BYE_'
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION fgetPlayerBye()
-- returns player _BYE_
	RETURNS integer
	AS
	$body$
		SELECT playerid
		FROM players
		WHERE playername = '_BYE_'
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION foponents(p integer)
-- returns list of player p's oponents
	RETURNS SETOF integer
	AS
	$body$
		SELECT matchwinner AS oponents
		FROM matches
		WHERE matchloser = $1
		UNION
			SELECT matchloser 
			FROM matches
			WHERE matchwinner = $1
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION fwins (p integer)
-- returns number of matches won by player p
	RETURNS bigint
	AS
	$body$
		SELECT COUNT(*) AS totalwins
			FROM(
				SELECT matchwinner FROM matches WHERE matchwinner = $1
				AND draw = false
			) AS wins
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION flosses (p integer)
-- returns number of matches lost by player p
	RETURNS bigint
	AS
	$body$
		SELECT COUNT(*) AS totallosses
			FROM(
				SELECT matchloser FROM matches WHERE matchloser = $1
				AND draw = false
			) AS losses
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION fdraws (p integer)
-- returns number of matches drwan by player p
	RETURNS bigint
	AS
	$body$
		SELECT COUNT(*) AS totaldraws
			FROM(
				SELECT * FROM matches
				WHERE
				(matchwinner = $1 AND draw = false)
				OR
				(matchloser = $1 AND draw = false)
			) AS draws
	$body$
	LANGUAGE sql
;

CREATE OR REPLACE FUNCTION falreadyPlayed (p1 integer, p2 integer)
-- returns the number of times p1 and p2 played match
	RETURNS bigint
	AS
	$body$
		SELECT COUNT (*) from matches
			WHERE matchwinner = $1 AND matchloser = $2
	        OR matchwinner = $2 AND matchloser = $1
	$body$
	LANGUAGE sql
;