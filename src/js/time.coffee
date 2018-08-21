# glass = require "glass-gauge"
# Gauge = glass.Gauge

suncalc = require './suncalc.js'


{Gauge} = require '/home/boris/work/glass-gauge/src/coffee/gauge.coffee'


export add = ->

  Gauge.create
    "Time":
      title:    ""
      scale:    "clk":
        presets:   ["Clock"]
        v1:     24
        number:
          v0:         0
          v1:         22
          divisions:  11
          offset:     -150
          rotate:      0
        tick:
          offset1:      -60
          offset2:      -100
          v1:           24
          divisions:    24
        subtick:
          offset1:      -50
          offset2:      -30
          v1:           24
          divisions:    60
        quantity:
          "Dawn":
            indicator: "dawn":
              type:    "bar"
              color:   "grey"
              width:   40
          "Dusk":
            indicator: "dusk":
              type:    "bar"
              invert:  true
              color:   "grey"
              width:   40
          "H":
            indicator: "hours":
              type:       "pointer"
              shape:      "line"
              dimension:  [120, 320]
              thickness:  30
          "M":
            scale_factor: 2.5
            indicator: "minutes":
              type:       "pointer"
              shape:      "line"
              dimension:  [70, 330]
              thickness:  20
          "S":
            scale_factor: 2.5
            indicator: "seconds":
              type:       "pointer"
              shape:      "line"
              dimension:  [-40, 360]
              thickness:  5
              color:      "red"
              speed:      .15

  tick = ->
    time = new Date
    #
    s = time.getSeconds()
    m = time.getMinutes() + s/60
    h12 = time.getHours() %% 12 + m/60
    h24 = time.getHours()       + m/60
    #
    Gauge.setValue      "Time": {H: h24 }
    Gauge.setValue      "Time": {M: m}
    Gauge.setValue      "Time": {S: s}
    #
  setInterval tick, 1000

  hours = (time) ->
    time.getHours() + 
    ( time.getMinutes() + 
        time.getSeconds()/60 )/60

  night_time = ->
    noordwijk = suncalc.getTimes new Date(), 52.233405, 4.437712
    Gauge.setValue    "Time": {Dawn: hours(noordwijk.sunrise) }
    Gauge.setValue    "Time": {Dusk: hours(noordwijk.sunset)  }
  # setInterval night_time, 1000   # 3h

  night_time()

  # noordwijk = suncalc.getTimes new Date(), 52.233405, 4.437712
  # console.log "dusk", hours(noordwijk.sunset)
  # Gauge.setValue    "Time": {Dawn: hours(noordwijk.sunrise) }
  # Gauge.setValue    "Time": {Dusk: hours(noordwijk.sunset)  }
