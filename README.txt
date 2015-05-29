
********** Project 2: Tournament: swiss pairing implementation *******

A/ SQL database
===============
The database is created by running the psql command
\i tournament.sql
The tournament.sql file contains all the table, view and function definitions

1/Tables:
-------
- players
- matches

2/ Views:
---------
vdrawplayed (view used in vplayerstandingscomplete)
vmatchesdraw (view used in vplayerstandings)
vmatcheslost (view used in vplayerstandings)
vmatchesplayed (view used in vplayerstandings)
vmatcheswon ((view used in vplayerstandings)
vnotplayedbye (view returns list of players with no 'bye')
vomwbye (view used in vplayerstandingscomplete)
vplayedbye (view used in vplayerstandingscomplete)
vplayerstandings (view player standings used in python function)
vwinloss (view used in vplayerstandings)
vplayerstandingscomplete (view returns playerid, playername,wins,losses,draws,matches,bye)


3/ Functions:
-------------
- falreadyplayed (reurns 1 if p1 and p2 have a match registered)
- fbyeid (returns the playerid for _BYE_)
- fcountplayers (returns registered players count)
- fdraws (returns number of draws for a player)
- fgetplayerbye (returns player _BYE_)
- fwins (returns number of wins for a player)
- flosses (returns number of losses for a player)
- fmatches (returns number of matches for a player)
- fnextplayerid (returns next playerid in the sequence)
- foponents (returns list of player p's oponents)
- fomw (returns the OMW for player p)
- fplayeromw (uses fomw and returns 0 if fomw is null)

B/ Additional python functions:
===============================
1/ registerBye():
Function to register _BYE_ player required to support odd number of players"""
2/ alreadyPlayed(p1, p2):
Checks whether p1 and p2 have played a match
3/ processBye(standings):
processes the 'bye' situation if odd number of registered players

C/ Extra credit implementation:
============================

1/ Preventing rematches between players:
----------------------------------------
This feature is handled thru a helper funtion called falreadyPlayed(p1,p2) that takes in 2 players p1 and p2 then returns 1 if there's a recorded match in the matches table. 0 otherwise.
In the normal flow of the competition players are paired before they can play a match. So it's logical to call this function before commiting the pairing between two players.
It output a message like:
"26 and 1 have already played!"

But to maintain consistancy and integrity the same function is called before recording a match in the matches table.
It prints a message like:
Skipped : (25, 27) pair already played!!!
Skipped : (28, 29) pair already played!!!

2/ Don't assume even number of registered players:
--------------------------------------------------
To get this part working I opted for a solution that registers a special player (_BYE_) right in the begining when the python module tournament.py is invoked via a python function: registerBye().

Before pairing starts (in the swissPairings() function) we check if the total number of registered players is odd. If the number is odd we process the "bye" situation by calling the helper function processBye(standingsList) passing in the playerStanding list where we:

- use the postgres function fbyeid() to get the id of _BYE_.
NOTE: _BYE_ is reserved and cannot be registered with the python function registerPlayer(p)
- pick a player at random from a choice list of players who has no 'bye' using the postgres view vnotPlayedBye
- record a match between the randomly picked player and _BYE_ as the matchloser
- remove the randomly picked player from the playerstanding list.
The list remains sorted and is returned with an even number of players to be swiss-paired

3/ Support games with a tie:
----------------------------
This feature is implemented with a column (draw) added to the matches table. Bye default the value is set to 'false' in the fuction prototype.
If the value is true then there is a tie (draw) between the matchwinner and the matchloser.
This is taken into account when counting wins and loses

4/ When 2 players have the same number of wins, rank them acording the ----------------------------------------------------------------------
their OMW:
----------
This feature is implemented by including the player's OMW in the vplayerstandings view sorted by wins and OMW.

C/ Test Runs validation:
========================

1/ Required Assignement Unit Tests Results:
-------------------------------------------
vagrant@vagrant-ubuntu-trusty-32:/vagrant/tournament$ python tournament_test.py
1. Old matches can be deleted.
2. Player records can be deleted.
3. After deleting, countPlayers() returns zero.
4. After registering a player, countPlayers() returns 1.
5. Players can be registered and deleted.
6. Newly registered players appear in the standings with no matches.
7. After a match, players have updated standings.
8. After one match, players with one win are paired.
Success!  All tests pass!

Extra Credits runs:
-------------------

1/ Even Number of Registered Players

(using the test case from Wikipedia:
http://en.wikipedia.org/wiki/Swiss-system_tournament)

tournament.registerPlayer('p1')
tournament.registerPlayer('p2')
tournament.registerPlayer('p3')
tournament.registerPlayer('p4')
tournament.registerPlayer('p5')
tournament.registerPlayer('p6')
tournament.registerPlayer('p7')
tournament.registerPlayer('p8')

player before matches played:

 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       17 | p1         |    0 |      0 |     0 |   0 |       0 |
       18 | p2         |    0 |      0 |     0 |   0 |       0 |
       19 | p3         |    0 |      0 |     0 |   0 |       0 |
       20 | p4         |    0 |      0 |     0 |   0 |       0 |
       21 | p5         |    0 |      0 |     0 |   0 |       0 |
       22 | p6         |    0 |      0 |     0 |   0 |       0 |
       23 | p7         |    0 |      0 |     0 |   0 |       0 |
       24 | p8         |    0 |      0 |     0 |   0 |       0 |
(8 rows)

- first round:
tournament.reportMatch(17, 21)
tournament.reportMatch(18, 22)
tournament.reportMatch(19, 23)
tournament.reportMatch(20, 24)

player standings
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       17 | p1         |    1 |      0 |     0 |   0 |       1 |
       18 | p2         |    1 |      0 |     0 |   0 |       1 |
       19 | p3         |    1 |      0 |     0 |   0 |       1 |
       20 | p4         |    1 |      0 |     0 |   0 |       1 |
       21 | p5         |    0 |      1 |     0 |   1 |       1 |
       22 | p6         |    0 |      1 |     0 |   1 |       1 |
       23 | p7         |    0 |      1 |     0 |   1 |       1 |
       24 | p8         |    0 |      1 |     0 |   1 |       1 |
(8 rows)

- second round:
tournament.reportMatch(17, 19)
tournament.reportMatch(18, 20)
tournament.reportMatch(21, 23)
tournament.reportMatch(22, 24)

player standings
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       17 | p1         |    2 |      0 |     0 |   2 |       2 |
       18 | p2         |    2 |      0 |     0 |   2 |       2 |
       19 | p3         |    1 |      1 |     0 |   2 |       2 |
       20 | p4         |    1 |      1 |     0 |   2 |       2 |
       21 | p5         |    1 |      1 |     0 |   2 |       2 |
       22 | p6         |    1 |      1 |     0 |   2 |       2 |
       23 | p7         |    0 |      2 |     0 |   2 |       2 |
       24 | p8         |    0 |      2 |     0 |   2 |       2 |
(8 rows)

- third round (using the swissPairings function):
[(17, 'p1', 18, 'p2'), (19, 'p3', 20, 'p4'), (21, 'p5', 22, 'p6'), (23, 'p7', 24, 'p8')]
tournament.reportMatch(17, 18)
tournament.reportMatch(20, 19)
tournament.reportMatch(21, 22, 'true') -- draw
tournament.reportMatch(23, 24)

player standings
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       17 | p1         |    3 |      0 |     0 |   5 |       3 |
       18 | p2         |    2 |      1 |     0 |   6 |       3 |
       20 | p4         |    2 |      1 |     0 |   3 |       3 |
       19 | p3         |    1 |      2 |     0 |   6 |       3 |
       21 | p5         |    1 |      1 |     1 |   5 |       3 |
       22 | p6         |    1 |      1 |     1 |   4 |       3 |
       23 | p7         |    1 |      2 |     0 |   3 |       3 |
       24 | p8         |    0 |      3 |     0 |   4 |       3 |
(8 rows)


2/ Odd Number of Registered Players (with tied games..)
-------------------------------------------------------
tournament.registerPlayer('p1')
tournament.registerPlayer('p2')
tournament.registerPlayer('p3')
tournament.registerPlayer('p4')
tournament.registerPlayer('p5')

player standings before matches:
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       25 | p1         |    0 |      0 |     0 |   0 |       0 |
       26 | p2         |    0 |      0 |     0 |   0 |       0 |
       27 | p3         |    0 |      0 |     0 |   0 |       0 |
       28 | p4         |    0 |      0 |     0 |   0 |       0 |
       29 | p5         |    0 |      0 |     0 |   0 |       0 |
(5 rows)


- first round using swissPairings function:
[(25, 'p1', 27, 'p3'), (28, 'p4', 29, 'p5')]
26 gets a 'bye' and registers a win
 matchid | matchwinner | matchloser | draw
---------+-------------+------------+------
      24 |          26 |          1 | f
(1 row)

tournament.reportMatch(25, 27)
tournament.reportMatch(28, 29)

player standings:
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       25 | p1         |    1 |      0 |     0 |   0 |       1 |
       26 | p2         |    1 |      0 |     0 |   0 |       1 |    1
       28 | p4         |    1 |      0 |     0 |   0 |       1 |
       27 | p3         |    0 |      1 |     0 |   1 |       1 |
       29 | p5         |    0 |      1 |     0 |   1 |       1 |
(5 rows)

- second round:
28 gets a bye, registers a free win

tournament.reportMatch(25, 26)
tournament.reportMatch(27, 29)

player standings:
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       25 | p1         |    2 |      0 |     0 |   2 |       2 |
       28 | p4         |    2 |      0 |     0 |   0 |       2 |    1
       26 | p2         |    1 |      1 |     0 |   2 |       2 |    1
       27 | p3         |    1 |      1 |     0 |   2 |       2 |
       29 | p5         |    0 |      2 |     0 |   3 |       2 |
(5 rows)

- third round:
29 gets a bye, registers a free win

tournament.reportMatch(28, 25, 'true')
tournament.reportMatch(27, 26)

player standings:
 playerid | playername | wins | losses | draws | omw | matches | pbye
----------+------------+------+--------+-------+-----+---------+------
       25 | p1         |    2 |      0 |     1 |   6 |       3 |
       27 | p3         |    2 |      1 |     0 |   4 |       3 |
       28 | p4         |    2 |      0 |     1 |   3 |       3 |    1
       29 | p5         |    1 |      2 |     0 |   5 |       3 |    1
       26 | p2         |    1 |      2 |     0 |   4 |       3 |    1
(5 rows)

3/ No rematch:
--------------
>>> tournament.swissPairings()
Bye-player 26 is the lucky one
26 and 1 have already played!
No match reported...
Bye-player 26 recorded a win
Before removing By-player 26 from standings
After removing By-player 26 from standings
Skipped : (25, 27) pair already played!!!
Skipped : (28, 29) pair already played!!!
[]
>>>
