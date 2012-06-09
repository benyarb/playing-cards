# Author: Ben Yarbrough
# requires underscore

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


# Do not instantiate Rank and Suit; instead, use these:
App.Models.ranks = (new App.Models.Rank(i) for i in [0...13])
App.Models.suits = (new App.Models.Suit(i) for i in [0...4])

_nextId = 0

class App.Models.Card
  constructor: (@rank, @suit) ->
    @id = "id#{_nextId++}"


class App.Models.Game
  cardsToTurn: null # override in subclass
  numberOfFoundations: 4
  numberOfTableauPiles: 7

  constructor: ->
    # Structure
    @faceUpTableauPiles = ([] for i in [0...@numberOfTableauPiles])
    @faceDownTableauPiles = ([] for i in [0...@numberOfTableauPiles])
    @stock = []
    @waste = []
    @foundations = ([] for i in [0...@numberOfFoundations])

    @undoStack = []

    # Locators
    @locators = {}
    @locators.foundations = (['foundations', i] for i in [0...@numberOfFoundations])
    @locators.faceDownTableauPiles = (['faceDownTableauPiles', i] for i in [0...@numberOfTableauPiles])
    @locators.faceUpTableauPiles = (['faceUpTableauPiles', i] for i in [0...@numberOfTableauPiles])
    @locators.all = [['stock'], ['waste'], @locators.foundations...,
      @locators.faceDownTableauPiles..., @locators.faceUpTableauPiles...]

    @deck = _(@createDeck()).shuffle()

  deal: ->
    deckCopy = @deck.slice(0)
    for i in [0...@faceDownTableauPiles.length]
      for j in [0...i]
        @faceDownTableauPiles[i].push(deckCopy.pop())
      @faceUpTableauPiles[i].push(deckCopy.pop())
    while deckCopy.length
      @stock.push(deckCopy.pop())

  createDeck: ->
    _(new App.Models.Card(rank, suit) \
      for rank in App.Models.ranks \
      for suit in App.Models.suits).flatten()


#------------------
# Controllers
#------------------

App.Controllers ?= {}

App.rootElement = '#card-table'

class App.Controllers.Card
  size: {width: 79, height: 123}
  element: null

  constructor: (@model) ->

  appendTo: (rootElement) ->
    @element = document.createElement('div')
    @element.className = 'card'
    @element.id = @model.id
    $(@element).css(@size)
    $(rootElement).append(@element)

  destroy: -> $(@element).remove()

  setRestingState: (pos, zIndex, faceUp) ->
    @restingState =
      position: _.clone(pos)
      zIndex: zIndex
      faceUp: faceUp

  jumpToRestingPosition: ->
    currentState = _(@restingState).clone()
    $(@element).queue (next) =>
      $(@element).css(zIndex: currentState.zIndex).css(currentState.position)
      next()

  animateToRestingPosition: (options, liftoff=true) ->
    currentState = _(@restingState).clone()
    $(@element).queue (next) =>
      $(@element).css zIndex: currentState.zIndex + if liftoff then 1000 else 0
      next()
    $(@element).animate(currentState.position, options)
    $(@element).queue (next) =>
      $(@element).css zIndex: currentState.zIndex
      next()

  jumpToRestingFace: ->
    currentState = _(@restingState).clone()
    $(@element).queue (next) =>
      $(@element).css backgroundPosition: @_getBackgroundPosition(currentState.faceUp)
      next()

  # This method flips the card. Only call it if the face state changed
  animateToRestingFace: (options) ->
    $(@element).animate {scale: 1.08},
      duration: options.duration / 9
      easing: 'linear'
    $(@element).animate {scaleX: 0},
      duration: options.duration * 3/9
      easing: 'linear'
    @jumpToRestingFace() # queue new background image
    $(@element).animate {scaleX: 1},
      duration: options.duration * 4/9
      easing: 'linear'
    $(@element).animate {scale: 1},
      duration: options.duration / 9
      easing: 'linear'

  _getBackgroundPosition: (faceUp) ->
    [width, height] = [@size.width, @size.height]
    if faceUp
      left = @model.rank.value * width
      top = 'CDHS'.indexOf(@model.suit.letter()) * height
    else
      [left, top] = [2 * width, 4 * height]
    "-#{left}px -#{top}px"

class App.Controllers.Test
  constructor: -> new App.Models.Game