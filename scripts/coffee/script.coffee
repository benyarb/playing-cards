# Author: Ben Yarbrough
# Requires Underscore.js - http://underscorejs.org

# Assign global scope to the root variable
root = exports ? this

# Create global App object
root.App ?= {}


#------------------
# Models
#------------------

App.Models ?= {}

# Immutable singleton
class App.Models.Rank
  constructor: (@value) ->

  letter: ->
    'A23456789TJQK'[@value]
  nextLower: ->
    if @value is 0 then null else App.Models.ranks[@value - 1]
  nextHigher: ->
    if @value is 12 then null else App.Models.ranks[@value + 1]

# Immutable singleton
class App.Models.Suit
  constructor: (@value) ->

  letter: ->
    'CDHS'.charAt(@value) # clubs, diamonds, hearts, spades
  color: ->
    if @letter() is 'C' or @letter() is 'S' then 'black' else 'red'
  name: ->
    if @letter() is 'C'
      'clubs'
    else if @letter() is 'D'
      'diams'
    else if @letter() is 'H'
      'hearts'
    else
      'spades'


# Do not instantiate Rank and Suit; instead, use these:
App.Models.ranks = (new App.Models.Rank(i) for i in [0...13])
App.Models.suits = (new App.Models.Suit(i) for i in [0...4])

_nextId = 0

class App.Models.Card
  constructor: (@rank, @suit) ->
    @id = "id#{_nextId++}"


class App.Models.Game
  constructor: (@numberOfPlayers = 4) ->
    # Setup empty player hands, defaults to 4 players
    @players = ([] for i in [0...@numberOfPlayers])

    # Create a shuffled deck
    # Uses Fischer-Yates algorithm - http://bwy.me/4c
    # via Underscore.js - http://underscorejs.org/#shuffle
    @deck = _.shuffle(@createDeck())

  deal: ->
    deckCopy = @deck.slice(0)
    
    # Determine how many cards will be left-over
    spareCards = deckCopy.length % @numberOfPlayers

    # Deal the cards evenly
    while deckCopy.length - spareCards
      for i in [0...@players.length]
        @players[i].push(deckCopy.pop())

    # Stash the left-over cards
    @spareCards = deckCopy

    # Return players/hands/cards
    @players

  createDeck: ->
    # Underscore's flatten function: http://underscorejs.org/#flatten
    _.flatten(new App.Models.Card(rank, suit) \
      for rank in App.Models.ranks \
      for suit in App.Models.suits)


#------------------
# Views
#------------------

App.Views ?= {}

# View(s) will be appended to this element
App.rootElement = '#card-table'

# Loop through players and hands for card display
# <% %> ERB-style delimiters
# underscore's _.each function: http://underscorejs.org/#each
App.Views.table = "
    <% _.each(hands, function(hand, player) { %>
      <div class='well'>
        <h2>Player <%= player + 1 %></h2>
        
        <div class='hand'>
          <% _.each(hand, function(card) { %>
            <span class='card rank-<%= card.rank.letter().toLowerCase() %> <%= card.suit.name() %>'>
              <span class='rank'><%= card.rank.letter() %></span>
              <span class='suit'>&<%= card.suit.name() %>;</span>
            </span>
          <% }); %>
        </div>
      </div>
    <% }); %>
  "


#------------------
# Controllers
#------------------

App.Controllers ?= {}

class App.Controllers.Play
  constructor: (@numberOfPlayers = 4) ->
    @model = new App.Models.Game(@numberOfPlayers)
    @hands = @model.deal()
    @rootElement = $(App.rootElement)[0]
    @view = App.Views.table

  setupTable: ->
    # Make sure the table is clear
    $(@rootElement).empty()
    
    # Underscore templating: http://underscorejs.org/#template
    @table = _.template(@view, {hands : @hands})

    # Go!
    $(@rootElement).append(@table)

  
#------------------
# Events
#------------------

$ ->
  # Play Button
  $('#play').click ->
    # Get number of players from select box
    players = $('#choose-players').val()

    # Shuffle, deal, show
    game = new App.Controllers.Play(players)
    game.setupTable()

  