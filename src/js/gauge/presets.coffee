{merge}         = require './helpers.coffee'

exports.settings = (unit, config) ->
  cfg = defaults[unit]
  if config.presets?
    for preset_name in config.presets
      cfg = merge cfg, presets[unit][preset_name]
  return merge cfg, config



defaults =
  gauge:
    title:        "Title"
    width:        1000
    height:       1000
  quantity:
    value:        0
    scale_factor: 1
    stepIncrement: 0.1
  scale:
    v0:           0
    v1:           100
    label:        ""
    unit:         ""
    barWidth:     100
    cyclic:       false
    track:
      color:    "lightgrey"
    tick:
      division:     2
      thickness:    5
      color:    "black"
    subtick:
      thickness:    3
      color:    "black"
      division:     2
    number:
      color:    "black"
      division:     2
  indicator:
    color:      "black"
    decimals:   1
    invert:  false          # switch opaque/transparent parts of bar
    out_of_range: true
    offset:   0




presets =
  scale:
    "Room_Temperature":
      label:          "T"
      unit:           "°C"
      v0:             10
      v1:             30
      tick:
        v0:           10
        v1:           30
        divisions:    4
      subtick:
        v0:           10
        v1:           30
        divisions:    20
      number:
        v0:               10
        v1:               30
        divisions:        2

    "Clock":
      type:         "circle"
      cyclic:       true
      v0:           0
      v1:           12
      tick:
        v0:         0
        v1:         12
        divisions:  12
      subtick:
        v0:         0
        v1:         12
        divisions:  60
      track:  color: "none"

    "Ticks_Left":
      tick:
        offset1:      -60
        offset2:      -100
      subtick:
        offset1:      -60
        offset2:      -70
      number:
        offset:       -180

    "Ticks_Right":
      tick:
        offset1:      60
        offset2:      100
      subtick:
        offset1:      60
        offset2:      70
      number:
        offset:       180
