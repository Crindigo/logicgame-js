/*
    Logic/Computer Game Code
    Copyright (c) 2012 Indiven LLC

    MIT License
*/

var ROWS = 10;
var COLS = 10;
var D_UP = 0, D_RIGHT = 1, D_DOWN = 2, D_LEFT = 3;
var BLOCKS = [];
var PARTS = [];
var PACKETS = [];

var SPRITES = {
    wire_up: 0x257D,
    wire_right: 0x257E,
    wire_down: 0x257F,
    wire_left: 0x257C,

    wire_down_right: 0x250E,
    wire_left_down: 0x2511,
    wire_up_left: 0x251A,
    wire_right_up: 0x2515,
    wire_down_left: 0x2512,
    wire_left_up: 0x2519,
    wire_up_right: 0x2516,
    wire_right_down: 0x250D
};

var buildPartCache = function() {
    PARTS = [];
    for ( var i = 0; i < BLOCKS.length; i++ ) {
        if ( BLOCKS[i].part ) {
            PARTS.push(BLOCKS[i].part);
        }
    }
};

var gameTick = function(t) {
    var i, l = PARTS.length;
    for ( i = 0; i < l; i++ ) {
        PARTS[i].ticked = false;
    }

    for ( i = 0; i < l; i++ ) {
        PARTS[i].tick(t);
        PARTS[i].ticked = true;
    }

    //console.log('Ticked ' + t);
};

var TICK = 0, TICKTIME = 1000;
var IntervalID;
var gameLoop = function() {
    buildPartCache();
    renderTable();

    IntervalID = setInterval(function() {
        gameTick(++TICK);
        renderTable();
    }, TICKTIME);
};

var pauseLoop = function() {
    clearInterval(IntervalID);
};

var oppositeDir = function(d) {
    switch ( d ) {
        case D_UP: return D_DOWN;
        case D_RIGHT: return D_LEFT;
        case D_DOWN: return D_UP;
        case D_LEFT: return D_RIGHT;
    }
};

var createTable = function()
{
    for ( var i = 0; i < ROWS * COLS; i++ ) {
        var block = $('<div></div>');
        block.addClass('block');
        block.attr('id', 'block' + i);
        $('#table_container').append(block);

        var b = new BlockInfo(block, new Pos(i % COLS, Math.floor(i / COLS)));
        BLOCKS.push(b);
    }
};

var renderTable = function()
{
    // in the future, should only re-render changed blocks (though if it's converted to Canvas, it'll probably
    // be rewritten anyway).
    for ( var i = 0; i < ROWS * COLS; i++ ) {
        BLOCKS[i].render();
    }
};

var getBlock = function(x, y)
{
    var id = y * COLS + x;
    return BLOCKS[id];
};

var getBlockDiv = function(x, y)
{
    var id = y * COLS + x;
    return $('#block' + id);
};

var Pos = function(x, y) {
    this.x = x;
    this.y = y;
};
Pos.prototype = {
    up: function() {
        return this.y == 0 ? null : new Pos(this.x, this.y - 1);
    },
    down: function() {
        return (this.y == ROWS - 1) ? null : new Pos(this.x, this.y + 1);
    },
    left: function() {
        return this.x == 0 ? null : new Pos(this.x - 1, this.y);
    },
    right: function() {
        return (this.x == COLS - 1) ? null : new Pos(this.x + 1, this.y);
    },

    dir: function(o) {
        if ( !this.hasDir(o) ) {
            return null;
        }
        switch (o) {
            case 0: return this.up();
            case 1: return this.right();
            case 2: return this.down();
            case 3: return this.left();
        }
        return null;
    },
    hasDir: function(o) {
        switch (o) {
            case 0: return this.y > 0;
            case 1: return this.x < (COLS - 1);
            case 2: return this.y < (ROWS - 1);
            case 3: return this.x > 0;
        }
        return false;
    },

    index: function() {
        return this.y * COLS + this.x;
    }
};

var BlockInfo = function(el, pos) {
    this.construct(el, pos);
};

BlockInfo.prototype = {

    construct: function(el, pos) {
        this.$element = el;
        this.part = null;
        this.pos = pos;
    },

    render: function() {
        if ( this.part != null ) {
            this.part.render(this.$element);
        }
    },

    dir: function(o) {
        var p = this.pos.dir(o);
        return p == null ? null : BLOCKS[p.index()];
    },

    setPart: function(p) {
        this.part = p;
        p.block = this;
    }
};

var Packet = function(data) {
    this.data = data;
};
Packet.prototype = {
    toString: function() {
        return String(this.data);
    },

    type: function() {
        var typ = typeof this.data;
        if ( typ == 'object' ) {
            return $.isArray(this.data) ? 'array' : 'object';
        } else {
            return typ; // number, string, boolean, function
        }
    }
};

var Part = function() {
    this.construct();
};
Part.uniq = 0;

Part.prototype = {
    id: 0,
    packets: [],
    packetQueue: [],
    orientation: 0,
    inputs: [],
    outputs: [],
    block: null,
    ticked: false,
    mirrored: false,

    construct: function() {
        //this.id = ++Part.uniq;
    },

    render: function($el) {

    },

    isVertical: function(o) {
        if ( typeof o == 'undefined' ) {
            o = this.orientation;
        }
        return o == D_UP || o == D_DOWN;
    },

    isHorizontal: function(o) {
        return !this.isVertical(o);
    },

    setOrientation: function(o) {
        // t, r, b, l = 0, 1, 2, 3
        var cur = this.orientation;
        if ( cur == o || o < 0 || o > 3 ) {
            return this;
        }

        // find the number of times we need to rotate right
        var rot;
        if ( o < cur ) {
            rot = 4 - (cur - o);
        } else {
            rot = o - cur;
        }

        // shift the inputs and outputs array values
        var i;
        for ( i = 0; i < this.inputs.length; i++ ) {
            this.inputs[i] = (this.inputs[i] + rot) % 4;
        }
        for ( i = 0; i < this.outputs.length; i++ ) {
            this.outputs[i] = (this.outputs[i] + rot) % 4;
        }

        this.orientation = o;
        return this;
    },

    mirror: function() {
        // if current orientation is up/down, swap left/right ports
        // if current orientation is left/right, swap up/down ports
        var i;
        for ( i = 0; i < this.inputs.length; i++ ) {
            if ( this.isVertical() && this.isHorizontal(this.inputs[i]) ) {
                this.inputs[i] = oppositeDir(this.inputs[i]);
            } else if ( this.isHorizontal() && this.isVertical(this.inputs[i]) ) {
                this.inputs[i] = oppositeDir(this.inputs[i]);
            }
        }
        for ( i = 0; i < this.outputs.length; i++ ) {
            if ( this.isVertical() && this.isHorizontal(this.outputs[i]) ) {
                this.outputs[i] = oppositeDir(this.outputs[i]);
            } else if ( this.isHorizontal() && this.isVertical(this.outputs[i]) ) {
                this.outputs[i] = oppositeDir(this.outputs[i]);
            }
        }

        this.mirrored = !this.mirrored;
        return this;
    },

    hasInput: function(dir) {
        for ( var i = 0; i < this.inputs.length; i++ ) {
            if ( this.inputs[i] == dir ) {
                return true;
            }
        }
        return false;
    },

    acceptsPacket: function(dir, pkt) {
        return this.hasInput(dir);
    },

    pushPacket: function(dir, pkt) {
        if ( this.ticked ) {
            this.packets.push(pkt);
        } else {
            this.packetQueue.push(pkt);
        }
    }
};
