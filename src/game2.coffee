###
Logic/Computer Game Code
Copyright (c) 2012 Indiven LLC

MIT License
###

ROWS = 10
COLS = 10

D_UP = 0
D_RIGHT = 1
D_DOWN = 2
D_LEFT = 3

BLOCKS = [];
PARTS = [];
PACKETS = [];

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

buildPartCache = ->
  window.PARTS = (block.part for block in window.BLOCKS when block.part?)
  true

gameTick = (t) ->
  part.ticked = false for part in window.PARTS
  for part in window.PARTS
    part.tick t
    part.ticked = true
  true

TICK = 0
window.TICKTIME = 1000
IntervalID = 0

gameLoop = ->
  buildPartCache()
  renderTable()

  IntervalID = setInterval ->
    gameTick ++TICK
    renderTable()
    true
  , TICKTIME

pauseLoop = ->
  clearInterval IntervalID

oppositeDir = (d) ->
  switch d
    when D_UP then D_DOWN
    when D_RIGHT then D_LEFT
    when D_DOWN then D_UP
    when D_LEFT then D_RIGHT
    else null

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

renderTable = ->
  # should really only re-render changed blocks
  block.render() for block in window.BLOCKS
  true

getBlock = (x, y) ->
  window.BLOCKS[y * window.COLS + x]

getBlockDiv = (x, y) ->
  $ "#block#{y * window.COLS + x}"

class BaseObject
  @use: (obj) ->
    for key, value of obj
      @::[key] = value
    this

class Pos
  constructor: (@x, @y) ->

  up: ->
    if @y == 0 then null else new Pos @x, @y - 1
  down: ->
    if (@y == window.ROWS - 1) then null else new Pos @x, @y + 1
  left: ->
    if @x == 0 then null else new Pos @x - 1, @y
  right: ->
    if (@x == window.COLS - 1) then null else new Pos @x + 1, @y

  dir: (o) ->
    return null if !@hasDir o

    switch o
      when D_UP then @up()
      when D_RIGHT then @right()
      when D_DOWN then @down()
      when D_LEFT then @left()
      else null

  hasDir: (o) ->
    switch o
      when D_UP then @y > 0
      when D_RIGHT then @x < (window.COLS - 1)
      when D_DOWN then @y < (window.ROWS - 1)
      when D_LEFT then @x > 0
      else false

  index: ->
    @y * window.COLS + @x

class BlockInfo
  constructor: (@element, @pos) ->
    @part = null

  render: ->
    @part.render(@element) if @part?

  dir: (o) ->
    p = @pos.dir(o)
    if p? then window.BLOCKS[p.index()] else null

  setPart: (p) ->
    @part = p
    p.block = @

class Packet
  constructor: (@data) ->

  toString: ->
    return String(@data)

  type: ->
    typ = typeof @data
    if typ == 'object'
      if $.isArray @data then 'array' else 'object'
    else
      typ

PART_UNIQ = 0

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

  isVertical: (o) ->
    if not o? then o = @orientation
    o == D_UP || o == D_DOWN

  isHorizontal: (o) ->
    not @isVertical(o)

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

# exports
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