# Author: Ben Yarbrough
# requires underscore - http://underscorejs.org

# assign global scope to the root variable
root = exports ? this

# create global App object
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
  symbol: ->
    if @letter() is 'C'    
      '&clubs;'
    else if @letter() is 'D'
      '&diams;'
    else if @letter() is 'H'
      '&hearts;'
    else
      '&spades;'


# Do not instantiate Rank and Suit; instead, use these:
App.Models.ranks = (new App.Models.Rank(i) for i in [0...13])
App.Models.suits = (new App.Models.Suit(i) for i in [0...4])

_nextId = 0

class App.Models.Card
  constructor: (@rank, @suit) ->
    @id = "id#{_nextId++}"


class App.Models.Game
  constructor: (@numberOfPlayers = 4) ->
    # Setup Empty Player Hands, Defaults to 4 Players
    @players = ([] for i in [0...@numberOfPlayers])

    # Create a Shuffled Deck
    # Uses Fischer-Yates Algorithm - http://bwy.me/4c
    # Via Underscore.js - http://underscorejs.org/#shuffle
    @deck = _.shuffle(@createDeck())

  deal: ->
    deckCopy = @deck.slice(0)
    spareCards = deckCopy.length % @numberOfPlayers

    while deckCopy.length - spareCards
      for i in [0...@players.length]
        @players[i].push(deckCopy.pop())

    @spareCards = deckCopy

    @players

  createDeck: ->
    _.flatten(new App.Models.Card(rank, suit) \
      for rank in App.Models.ranks \
      for suit in App.Models.suits)


#------------------
# Views
#------------------

App.Views ?= {}

App.rootElement = '#card-table'

App.Views.table = "
    <% _.each(hands, function(hand, player) { %>
      <h2>Player <%= player + 1 %></h2>
      
      <div class='hand'>
        <% _.each(hand, function(card) { %>
          <span class='<%= card.suit.color() %> card'><%= card.rank.letter() + card.suit.symbol() %></span>
        <% }); %>
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
    # make sure the table is clear
    $(@rootElement).empty()
    
    @table = _.template(@view, {hands : @hands})

    $(@rootElement).append(@table)

  
#------------------
# Events
#------------------

$ ->
  # Play Button
  $('#play').click ->
    players = $('#choose-players').val()
    game = new App.Controllers.Play(players)
    game.setupTable()



  