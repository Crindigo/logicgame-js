/*
    Logic/Computer Game Code
    Copyright (c) 2012 Indiven LLC

    MIT License
*/

var SimplePacketHandlerMixin = function() {};
SimplePacketHandlerMixin.prototype.tick = function(t) {
    this.handlePackets();
    this.packets = this.packetQueue;
    this.packetQueue = [];
};

// straight wire, defaults to down -> up connection at UP orientation.
var StraightWire = function() {
    this.construct();
};
StraightWire.prototype = new Part;
$.extend(StraightWire.prototype, SimplePacketHandlerMixin.prototype, {

    construct: function() {
        this.packets = [];
        this.packetQueue = [];
        this.inputs = [D_DOWN];
        this.outputs = [D_UP];
    },

    render: function($el) {
        var codes = {
            0: SPRITES.wire_up,
            1: SPRITES.wire_right,
            2: SPRITES.wire_down,
            3: SPRITES.wire_left
        };

        $el.text(String.fromCharCode(codes[this.orientation]));
        if ( this.packets.length > 0 || this.packetQueue.length > 0 ) {
            $el.css('color', '#0a0');
        } else {
            $el.css('color', '#000');
        }
    },

    handlePackets: function() {
        while ( this.packets.length > 0 ) {
            var pkt = this.packets.shift();
            var b = this.block.dir(this.outputs[0]);

            if ( b && b.part && b.part.acceptsPacket(oppositeDir(this.outputs[0]), pkt) ) {
                b.part.pushPacket(oppositeDir(this.outputs[0]), pkt);
            }
        }
    }
});

// curved wire, defaults to down -> right connection at UP orientation.
var CurvedWire = function() {
    this.construct();
};
CurvedWire.prototype = new StraightWire;
$.extend(CurvedWire.prototype, {

    construct: function() {
        this.packets = [];
        this.packetQueue = [];
        this.inputs = [D_DOWN];
        this.outputs = [D_RIGHT];
        this.mirrored = false;
    },

    render: function($el) {
        var codes = {
            0: SPRITES.wire_down_right,
            1: SPRITES.wire_left_down,
            2: SPRITES.wire_up_left,
            3: SPRITES.wire_right_up,
            4: SPRITES.wire_down_left,
            5: SPRITES.wire_left_up,
            6: SPRITES.wire_up_right,
            7: SPRITES.wire_right_down
        };

        var i = this.orientation + (this.mirrored ? 4 : 0);
        $el.text(String.fromCharCode(codes[i]));
        if ( this.packets.length > 0 || this.packetQueue.length > 0 ) {
            $el.css('color', '#0a0');
        } else {
            $el.css('color', '#000');
        }
    }
});

// makes wire construction easier to remember. just "WireFactory.{fromDir}{toDir}".
var WireFactory = {
    downUp: function() { return new StraightWire(); },
    leftRight: function() { return new StraightWire().setOrientation(D_RIGHT); },
    upDown: function() { return new StraightWire().setOrientation(D_DOWN); },
    rightLeft: function() { return new StraightWire().setOrientation(D_LEFT); },

    downRight: function() { return new CurvedWire(); },
    leftDown: function() { return new CurvedWire().setOrientation(D_RIGHT); },
    upLeft: function() { return new CurvedWire().setOrientation(D_DOWN); },
    rightUp: function() { return new CurvedWire().setOrientation(D_LEFT); },
    downLeft: function() { return new CurvedWire().mirror(); },
    leftUp: function() { return new CurvedWire().setOrientation(D_RIGHT).mirror(); },
    upRight: function() { return new CurvedWire().setOrientation(D_DOWN).mirror(); },
    rightDown: function() { return new CurvedWire().setOrientation(D_LEFT).mirror(); }
};

var PacketGenerator = function(data) {
    this.construct(data);
};
PacketGenerator.prototype = new Part;
$.extend(PacketGenerator.prototype, {

    construct: function(data) {
        this.outputs = [D_UP];
        this.packetData = data;
        this.shouldTickFn = function(t) { return true; };
    },

    setShouldTickFn: function(f) {
        this.shouldTickFn = f;
        return this;
    },

    render: function($el) {
        $el.text('G');
    },

    tick: function(t) {
        if ( !this.shouldTickFn(t) ) {
            return;
        }
        for ( var i = 0; i < this.outputs.length; i++ ) {
            var b = this.block.dir(this.outputs[i]);
            var pkt = new Packet(this.packetData);
            if ( b && b.part && b.part.acceptsPacket(oppositeDir(this.outputs[i]), pkt) ) {
                b.part.pushPacket(oppositeDir(this.outputs[i]), pkt);
                //console.log('Generator pulse ' + t);
            }
        }
    }
});

var Accumulator = function(inc) {
    this.construct(inc);
};
Accumulator.prototype = new Part;
$.extend(Accumulator.prototype, SimplePacketHandlerMixin.prototype, {

    construct: function(inc) {
        this.increment = inc;
        this.inputs = [D_DOWN];
        this.outputs = [D_UP];
    },

    render: function($el) {
        $el.text('+');
        if ( this.packets.length > 0 || this.packetQueue.length > 0 ) {
            $el.css('color', '#0a0');
        } else {
            $el.css('color', '#000');
        }
    },

    acceptsPacket: function(dir, pkt) {
        return this.hasInput(dir) && pkt.type() == 'number';
    },

    handlePackets: function() {
        while ( this.packets.length > 0 ) {
            var pkt = this.packets.shift();
            var b = this.block.dir(this.outputs[0]);

            if ( b && b.part && b.part.acceptsPacket(oppositeDir(this.outputs[0]), pkt) ) {
                pkt.data = pkt.data + this.increment;
                b.part.pushPacket(oppositeDir(this.outputs[0]), pkt);
            }
        }
    }
});

var ConsoleLogger = function(key) {
    this.construct(key);
};
ConsoleLogger.prototype = new Part;
$.extend(ConsoleLogger.prototype, SimplePacketHandlerMixin.prototype, {

    construct: function(key) {
        this.key = key;
        this.inputs = [D_UP, D_RIGHT, D_DOWN, D_LEFT];
        this.outputs = [];
    },

    render: function($el) {
        $el.text('>');
    },

    handlePackets: function() {
        while ( this.packets.length > 0 ) {
            var pkt = this.packets.shift();
            console.log("ConsoleLogger(" + this.key + "): " + pkt.toString());
        }
    }
});