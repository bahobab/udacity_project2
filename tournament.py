#!/usr/bin/env python
# 
# tournament.py -- implementation of a Swiss-system tournament
#

import psycopg2
import random

#global constant
BYE = '_BYE_'


def connect():
    """Connect to the PostgreSQL database.  Returns a database connection."""
    return psycopg2.connect("dbname=tournament")

def deleteMatches():
    """Remove all the match records from the database."""
    conn = connect()
    cursor = conn.cursor()
    cursor.execute("delete from matches;")
    conn.commit()
    conn.close()

def deletePlayers():
    """Remove all the player records from the database."""
    conn = connect()
    cursor = conn.cursor()
    cursor.execute("delete from players where playername <> '_BYE_';")
    conn.commit()
    conn.close()

def countPlayers():
    """Returns the number of players currently registered."""
    conn = connect()
    cursor = conn.cursor()
    cursor.execute("select * from fcountPlayers();")
    num = int(cursor.fetchone()[0])
    conn.close()
    return num

def registerPlayer(name):
    """Adds a player to the tournament database.
      
    The database assigns a unique serial id number for the player.  (This
    should be handled by your SQL database schema, not in your Python code.)
  
    Args:
      name: the player's full name (need not be unique).
    """
    if name <> BYE:
        conn = connect()
        cursor = conn.cursor()
        cursor.execute("insert into players (playername) values($$" + name + "$$);")
        conn.commit()
        conn.close()
    else:
        print "!!! WARNING !!!\n" + \
              BYE + " IS RESERVED WORD, CANNOT BE A PLAYER NAME"

def playerStandings():
    """Returns a list of the players and their win records, sorted by wins.

    The first entry in the list should be the player in first place, or a player
    tied for first place if there is currently a tie.

    Returns:
      A list of tuples, each of which contains (id, name, wins, matches):
        id: the player's unique id (assigned by the database)
        name: the player's full name (as registered)
        wins: the number of matches the player has won
        matches: the number of matches the player has played
    """
    conn = connect()
    cursor = conn.cursor()
    omw = list()
    standings = list()
    playerList = list()

    cursor.execute("select * from vplayerstandings;")
    playerList = cursor.fetchall()
    for tup in playerList:
        standings.append(tup[0:-1])
    conn.close()
    return standings

def reportMatch(winner, loser, draw = False):
    """Records the outcome of a single match between two players.

    Args:
      winner:  the id number of the player who won
      loser:  the id number of the player who lost
      tie: the outcome of the match is a tie: false by default
      if true then match results in a tie
    """

    global alreadyPlayed
    
    if not alreadyPlayed(winner, loser): # record only one match between 2 players for a given tournament 
        conn = connect()
        cursor = conn.cursor()
        cursor.execute("insert into matches (matchwinner, matchloser, draw) " + \
                       "values(" + str(winner) + "," + str(loser) + "," + str(draw) + ");")
        conn.commit()
        conn.close()
    else:
        print ( str(winner) + " and " + str(loser) + \
                " have already played!\nNo match reported...")
 
def swissPairings():
    """Returns a list of pairs of players for the next round of a match.
  
    Assuming that there are an even number of players registered, each player
    appears exactly once in the pairings.  Each player is paired with another
    player with an equal or nearly-equal win record, that is, a player adjacent
    to him or her in the standings.
  
    Returns:
      A list of tuples, each of which contains (id1, name1, id2, name2)
        id1: the first player's unique id
        name1: the first player's name
        id2: the second player's unique id
        name2: the second player's name
    """

    global alreadyPlayed
    
    def processBye(standings): # drop bye column in players table
        """helper function:
        1. takes a list of odd number of players
        2. picks a 'bye' player at random, gives him/her a win
        3. returns the list of standings minus the 'bye' player so number of players is odd"""
        
        global registerPlayer, countPlayers, reportMatch
        
        conn = connect()
        cursor = conn.cursor()
        byechoices = list()

            # make sure player 'BYE' id
        cursor.execute("select * from fbyeid();")
        byeid = cursor.fetchone()[0]
            # select players who have not played with player BYE
        cursor.execute("select * from vnotPlayedBye;")
        byechoices = cursor.fetchall()
            #get the next player with the 'playerbye' is false
        choice = random.choice(byechoices)
        byePlayer = choice[0]          
            #give byePlayer a win and matches played
        reportMatch(byePlayer, byeid)        
            #remove player byePlayer from standings
        for row in list(standings):
            if row[0] == byePlayer:
                standings.remove(row)
        return standings
        # -- end function --
                   
    pairs = []
    standings = playerStandings()
                
    if countPlayers() % 2 != 0:             # odd number of registered players
        standings = processBye(standings)   # give a player a 'bye'
    
    for i in range(0, len(standings), 2):
        if not alreadyPlayed(standings[i][0], standings[i+1][0]): # prevent rematch for a given tournament
           pairs.append((standings[i][0], standings[i][1], standings[i+1][0], standings[i+1][1]))
        else:
            print "Skipped : (" + str(standings[i][0]) + \
                  ", " + str(standings[i+1][0]) + ") pair already played!!!"
    return pairs

def alreadyPlayed(p1, p2):
    """helper function:
    1. takes 2 players p1, p2
    2. returns true if the 2 players already have a match recorded"""

    played = False
    conn = connect()
    cursor = conn.cursor()
    cursor.execute("select * from  " + \
                   "falreadyPlayed(" + str(p1) + "," + str(p2) +" );")
    if int(cursor.fetchall()[0][0]) != 0:
        played = True
    return played
    conn.close()
    # -- end function --                 
    
#main
def registerBye():
    """Function to register _BYE_ player required to support odd number of players"""
    global connect
    
    conn = connect()
    cursor = conn.cursor()
    cursor.execute("select * from fbyeid();")
    byeid = cursor.fetchone()[0]
    if byeid == None:
        cursor.execute("INSERT INTO players (playername) VALUES('" + BYE + "');")
        conn.commit()
    conn.close()

registerBye()
