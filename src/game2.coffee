# This file deals with some base variables, functions, and classes for the
# game. Included is some rendering code, utilities for grid positions, the
# BaseObject class (allows for easy use of traits), Packet class, and the base
# base Part class, the parent of all wires and computers.

#### Global Variable Setup

# The number of rows and columns in the grid.
ROWS = 10
COLS = 10

# Directional constants, used when configuring the input/output ports on Parts.
D_UP = 0
D_RIGHT = 1
D_DOWN = 2
D_LEFT = 3

# Arrays for tracking and caching game data.
BLOCKS = [];
PARTS = [];
PACKETS = [];

# List of "sprites" which are really just unicode characters (for now).
SPRITES = {
  wire_up: 0x257D
  wire_right: 0x257E
  wire_down: 0x257F
  wire_left: 0x257C

  wire_down_right: 0x250E
  wire_left_down: 0x2511
  wire_up_left: 0x251A
  wire_right_up: 0x2515
  wire_down_left: 0x2512
  wire_left_up: 0x2519
  wire_up_right: 0x2516
  wire_right_down: 0x250D
}

#### Global Functions
# Extracts and caches the list of parts from the full grid data.
buildPartCache = ->
  window.PARTS = (block.part for block in window.BLOCKS when block.part?)
  true

# Ticks the game, given parameter `t` which is the current tick number.
gameTick = (t) ->
  part.ticked = false for part in window.PARTS
  for part in window.PARTS
    part.tick t
    part.ticked = true
  true

# Variables for tracking the current tick number, tick interval, and the game's
# interval ID.
TICK = 0
window.TICKTIME = 1000
IntervalID = 0

# Starts executing the game loop.
gameLoop = ->
  buildPartCache()
  renderTable()

  IntervalID = setInterval ->
    gameTick ++TICK
    renderTable()
    true
  , TICKTIME

# Pauses the game loop by clearing the interval.
pauseLoop = ->
  clearInterval IntervalID

# Given a directional constant `d`, returns its opposite (left becomes right,
# up becomes down, etc.)
oppositeDir = (d) ->
  switch d
    when D_UP then D_DOWN
    when D_RIGHT then D_LEFT
    when D_DOWN then D_UP
    when D_LEFT then D_RIGHT
    else null

# Creates a grid of div elements and inserts them into an element with ID
# table_container. Also creates a list of `BlockInfo` objects for each element
# and stores them inside of `BLOCKS` for later use.
createTable = ->
  size = window.ROWS * window.COLS
  for i in [0...size]
    block = $ '<div></div>'
    block.addClass 'block'
    block.attr 'id', "block#{i}"
    $('#table_container').append block
    b = new BlockInfo block, (new Pos(i % window.COLS, Math.floor i / window.COLS))
    window.BLOCKS.push b
  true

# Renders each block in the list. Later on, this should only render blocks that
# have updated, but it seems to run fine for now.
renderTable = ->
  block.render() for block in window.BLOCKS
  true

# Gets the `BlockInfo` record at the given `x`, `y` position.
getBlock = (x, y) ->
  window.BLOCKS[y * window.COLS + x]

# Gets the jQuery div element at the given `x`, `y` position.
getBlockDiv = (x, y) ->
  $ "#block#{y * window.COLS + x}"

#### Class Definitions

# The BaseObject class contains one static `@use` method, which accepts an
# object `obj` and mixes in its properties to the class's instance properties.
class BaseObject
  @use: (obj) ->
    for key, value of obj
      @::[key] = value
    this

# The Pos class represents a grid position and contains utility methods for
# returning new Pos objects relative to the current position.
class Pos
  constructor: (@x, @y) ->

  # The following methods will return the corresponding Pos object for the
  # position up, down, left, or to the right. If the position would be outside
  # of the grid, `null` is returned.
  up: ->
    if @y == 0 then null else new Pos @x, @y - 1
  down: ->
    if (@y == window.ROWS - 1) then null else new Pos @x, @y + 1
  left: ->
    if @x == 0 then null else new Pos @x - 1, @y
  right: ->
    if (@x == window.COLS - 1) then null else new Pos @x + 1, @y

  # Similar to the above methods, dir accepts a directional constant `o` and
  # calls the proper direction method for the given value. If no position
  # exists in the direction, or the direction is invalid, `null` is returned.
  dir: (o) ->
    return null if !@hasDir o

    switch o
      when D_UP then @up()
      when D_RIGHT then @right()
      when D_DOWN then @down()
      when D_LEFT then @left()
      else null

  # Accepts a directional constant `o` and returns boolean true if a position
  # exists in that direction, false if not.
  hasDir: (o) ->
    switch o
      when D_UP then @y > 0
      when D_RIGHT then @x < (window.COLS - 1)
      when D_DOWN then @y < (window.ROWS - 1)
      when D_LEFT then @x > 0
      else false

  # Returns an integer index representing this position that can be used
  # inside of the `BLOCKS` array.
  index: ->
    @y * window.COLS + @x

# The BlockInfo class represents an element on the grid, and contains
# properties for referring to the underlying div element, and the part that
# lies within the block.
class BlockInfo
  constructor: (@element, @pos) ->
    @part = null

  # Renders the part on the inside, if it exists.
  render: ->
    @part.render(@element) if @part?

  # Returns the BlockInfo instance (if any) in the given direction from this
  # block. Returns null if none exists.
  dir: (o) ->
    p = @pos.dir(o)
    if p? then window.BLOCKS[p.index()] else null

  # Sets the underlying part, and updates the part's block property to point
  # to this block.
  setPart: (p) ->
    @part = p
    p.block = @

# The Packet class represents a packet of data that moves through all of the
# parts. Its only property is data.
class Packet
  constructor: (@data) ->

  toString: ->
    return String(@data)

  # Returns the type of the data: boolean, number, string, function, array,
  # or object.
  type: ->
    typ = typeof @data
    if typ == 'object'
      if $.isArray @data then 'array' else 'object'
    else
      typ

  dup: ->
    new Packet(@data)

PART_UNIQ = 0

# The Part class serves as the base for all wires and computers that can appear
# on the game grid.
class Part extends BaseObject

  uniqid: 0
  packets: []
  packetQueue: []
  orientation: 0
  mirrored: false
  inputs: []
  outputs: []
  block: null
  ticked: false

  constructor: ->
    @uniqid = ++PART_UNIQ

  render: (el) ->

  # The isVertical and isHorizontal methods return true if the orientation of
  # the part is up/down and right/left respectively.
  isVertical: (o) ->
    if not o? then o = @orientation
    o == D_UP || o == D_DOWN

  isHorizontal: (o) ->
    not @isVertical(o)

  # Changes the orientation of the part. All input/output ports are
  # automatically rotated to reflect the new value.
  setOrientation: (o) ->
    cur = @orientation
    return @ if (cur == o or o < 0 or o > 3)

    # find the number of times we need to rotate right
    rot = if o < cur then 4 - (cur - o) else o - cur

    for input, i in @inputs
      @inputs[i] = (input + rot) % 4

    for output, i in @outputs
      @outputs[i] = (output + rot) % 4

    @orientation = o
    @

  # Mirrors the part. If the current orientation is vertical, the left and
  # right i/o ports are swapped. If the orientation is horizontal, the up and
  # down ports are swapped.
  mirror: ->
    # if cur orientation is vert, swap left/right
    # else swap up/down
    for input, i in @inputs
      if (@isVertical() and @isHorizontal(input)) or (@isHorizontal() and @isVertical(input))
        @inputs[i] = oppositeDir input

    for output, i in @outputs
      if (@isVertical() and @isHorizontal(output)) or (@isHorizontal() and @isVertical(output))
        @outputs[i] = oppositeDir output

    @mirrored = not @mirrored
    @

  hasInput: (dir) ->
    dir in @inputs

  acceptsPacket: (dir, pkt) ->
    @hasInput dir

  pushPacket: (dir, pkt) ->
    if @ticked then @packets.push pkt else @packetQueue.push pkt

#### Exports

# The following statements are for exporting local variables, functions, and
# classes into the global namespace.
window.ROWS = ROWS
window.COLS = COLS
window.D_UP = D_UP
window.D_RIGHT = D_RIGHT
window.D_DOWN = D_DOWN
window.D_LEFT = D_LEFT
window.BLOCKS = BLOCKS
window.PARTS = PARTS
window.PACKETS = PACKETS
window.SPRITES = SPRITES

window.gameLoop = gameLoop
window.pauseLoop = pauseLoop
window.oppositeDir = oppositeDir
window.createTable = createTable
window.getBlock = getBlock
window.getBlockDiv = getBlockDiv

window.BaseObject = BaseObject
window.Pos = Pos
window.Packet = Packet
window.BlockInfo = BlockInfo
window.Part = Part