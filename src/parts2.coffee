###
Logic/Computer Game Code
Copyright (c) 2012 Indiven LLC

MIT License
###

Packet = window.Packet
Part = window.Part
oppositeDir = window.oppositeDir

PacketHandlerTrait =
  tick: (t) ->
    @handlePackets()
    @packets = @packetQueue
    @packetQueue = []

class StraightWire extends Part
  @use PacketHandlerTrait

  @spriteCodes: [
    window.SPRITES.wire_up
    window.SPRITES.wire_right
    window.SPRITES.wire_down
    window.SPRITES.wire_left
  ]

  constructor: ->
    super
    @inputs = [window.D_DOWN]
    @outputs = [window.D_UP]

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
    window.SPRITES.wire_down_right
    window.SPRITES.wire_left_down
    window.SPRITES.wire_up_left
    window.SPRITES.wire_right_up
    window.SPRITES.wire_down_left
    window.SPRITES.wire_left_up
    window.SPRITES.wire_up_right
    window.SPRITES.wire_right_down
  ]

  constructor: ->
    super
    @outputs = [window.D_RIGHT]
    @mirrored = false

  render: (el) ->
    i = @orientation + (if @mirrored then 4 else 0)
    el.text String.fromCharCode(CurvedWire.spriteCodes[i])
    el.css('color', if @packets.length > 0 or @packetQueue.length > 0 then '#0a0' else '#000')

WireFactory =
  downUp   : -> new StraightWire()
  leftRight: -> new StraightWire().setOrientation(window.D_RIGHT)
  upDown   : -> new StraightWire().setOrientation(window.D_DOWN)
  rightLeft: -> new StraightWire().setOrientation(window.D_LEFT)

  downRight: -> new CurvedWire()
  leftDown : -> new CurvedWire().setOrientation(window.D_RIGHT)
  upLeft   : -> new CurvedWire().setOrientation(window.D_DOWN)
  rightUp  : -> new CurvedWire().setOrientation(window.D_LEFT)

  downLeft : -> new CurvedWire()
  leftUp   : -> new CurvedWire().setOrientation(window.D_RIGHT).mirror()
  upRight  : -> new CurvedWire().setOrientation(window.D_DOWN).mirror()
  rightDown: -> new CurvedWire().setOrientation(window.D_LEFT).mirror()

class PacketGenerator extends Part
  constructor: (@data) ->
    @outputs = [window.D_UP]
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
    @inputs = [window.D_DOWN]
    @outputs = [window.D_UP]

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
    @inputs = [window.D_UP, window.D_RIGHT, window.D_DOWN, window.D_LEFT]

  render: (el) ->
    el.text '>'

  handlePackets: ->
    while @packets.length > 0
      pkt = @packets.shift()
      console.log "ConsoleLogger(#{@key}): #{pkt.toString()}"
    true


window.StraightWire = StraightWire
window.CurvedWire = CurvedWire
window.WireFactory = WireFactory
window.PacketGenerator = PacketGenerator
window.Accumulator = Accumulator
window.ConsoleLogger = ConsoleLogger
