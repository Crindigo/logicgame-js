###
Logic/Computer Game Code
Copyright (c) 2012 Indiven LLC

MIT License
###

Packet = window.Packet
Part = window.Part
oppositeDir = window.oppositeDir

D_UP = window.D_UP
D_DOWN = window.D_DOWN
D_LEFT = window.D_LEFT
D_RIGHT = window.D_RIGHT
SPRITES = window.SPRITES

PacketHandlerTrait =
  tick: (t) ->
    @handlePackets()
    @packets = @packets.concat @packetQueue
    @packetQueue = []

class StraightWire extends Part
  @use PacketHandlerTrait

  @spriteCodes: [
    SPRITES.wire_up
    SPRITES.wire_right
    SPRITES.wire_down
    SPRITES.wire_left
  ]

  constructor: ->
    super
    @inputs = [D_DOWN]
    @outputs = [D_UP]

  render: (el) ->
    el.text String.fromCharCode(StraightWire.spriteCodes[@orientation])
    el.css('color', if @packets.length > 0 or @packetQueue.length > 0 then '#0a0' else '#000')

  handlePackets: ->
    while @packets.length > 0
      pkt = @packets.shift()
      b = @block.dir @outputs[0]

      if b? and b.part? and b.part.acceptsPacket(oppositeDir(@outputs[0]), pkt)
        b.part.pushPacket(oppositeDir(@outputs[0]), pkt)
    true

class CurvedWire extends StraightWire
  @spriteCodes: [
    SPRITES.wire_down_right
    SPRITES.wire_left_down
    SPRITES.wire_up_left
    SPRITES.wire_right_up
    SPRITES.wire_down_left
    SPRITES.wire_left_up
    SPRITES.wire_up_right
    SPRITES.wire_right_down
  ]

  constructor: ->
    super
    @outputs = [D_RIGHT]
    @mirrored = false
    @packets = []
    @packetQueue = []

  render: (el) ->
    i = @orientation + (if @mirrored then 4 else 0)
    el.text String.fromCharCode(CurvedWire.spriteCodes[i])
    el.css('color', if @packets.length > 0 or @packetQueue.length > 0 then '#0a0' else '#000')

WireFactory =
  downUp   : -> new StraightWire()
  leftRight: -> new StraightWire().setOrientation(D_RIGHT)
  upDown   : -> new StraightWire().setOrientation(D_DOWN)
  rightLeft: -> new StraightWire().setOrientation(D_LEFT)

  downRight: -> new CurvedWire()
  leftDown : -> new CurvedWire().setOrientation(D_RIGHT)
  upLeft   : -> new CurvedWire().setOrientation(D_DOWN)
  rightUp  : -> new CurvedWire().setOrientation(D_LEFT)

  downLeft : -> new CurvedWire()
  leftUp   : -> new CurvedWire().setOrientation(D_RIGHT).mirror()
  upRight  : -> new CurvedWire().setOrientation(D_DOWN).mirror()
  rightDown: -> new CurvedWire().setOrientation(D_LEFT).mirror()

class PacketGenerator extends Part
  constructor: (@data) ->
    super
    @outputs = [D_UP]
    @shouldTickFn = (t) -> true

  setShouldTickFn: (fn) ->
    @shouldTickFn = fn
    @

  render: (el) ->
    el.text 'G'

  tick: (t) ->
    return null if not @shouldTickFn(t)

    for output, i in @outputs
      b = @block.dir output
      pkt = new Packet(@data)
      if b? and b.part? and b.part.acceptsPacket(oppositeDir(output), pkt)
        b.part.pushPacket(oppositeDir(output), pkt)
    true

class Accumulator extends Part
  @use PacketHandlerTrait

  constructor: (@inc) ->
    super
    @inputs = [D_DOWN]
    @outputs = [D_UP]

  render: (el) ->
    el.text '+'
    el.css('color', if @packets.length > 0 or @packetQueue.length > 0 then '#0a0' else '#000')

  acceptsPacket: (dir, pkt) ->
    @hasInput(dir) and pkt.type() == 'number'

  handlePackets: ->
    while @packets.length > 0
      pkt = @packets.shift()
      b = @block.dir(@outputs[0])
      if b? and b.part? and b.part.acceptsPacket(oppositeDir(@outputs[0]), pkt)
        pkt.data = pkt.data + @inc
        b.part.pushPacket(oppositeDir(@outputs[0]), pkt)
    true

class ConsoleLogger extends Part
  @use PacketHandlerTrait

  constructor: (@key) ->
    super
    @inputs = [D_UP, D_RIGHT, D_DOWN, D_LEFT]

  render: (el) ->
    el.text '>'

  handlePackets: ->
    while @packets.length > 0
      pkt = @packets.shift()
      console.log "ConsoleLogger(#{@key}): #{pkt.toString()}"
    true

class ArrayBuilder extends Part
  @use PacketHandlerTrait

  constructor: (@size) ->
    super
    @inputs = [D_DOWN]
    @outputs = [D_UP]

  render: (el) ->
    el.html "A<sup>#{@packets.length + @packetQueue.length}</sup>"

  handlePackets: ->
    if @packets.length >= @size
      output = @outputs[0]
      b = @block.dir output
      arr = (p.data for p in @packets.splice(0, @size))
      pkt = new Packet(arr)
      if b? and b.part? and b.part.acceptsPacket(oppositeDir(output), pkt)
        b.part.pushPacket(oppositeDir(output), pkt)

class DuhWinning extends Part
  @use PacketHandlerTrait

  constructor: ->
    super
    @inputs = []

  render: (el) ->
    el.text 'W'

  isWinner: (pkt) ->
    false

  acceptsPacket: (dir, pkt) ->
    @hasInput(dir) and @isWinner(pkt)

  handlePackets: ->
    if @packets.length > 0
      pkt = @packets.shift()
      alert 'You win!'
      window.pauseLoop()

window.StraightWire = StraightWire
window.CurvedWire = CurvedWire
window.WireFactory = WireFactory
window.PacketGenerator = PacketGenerator
window.Accumulator = Accumulator
window.ConsoleLogger = ConsoleLogger
window.ArrayBuilder = ArrayBuilder
window.DuhWinning = DuhWinning