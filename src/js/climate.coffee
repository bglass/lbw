insert_barometer()
    # Gauge.setValue barometer: P0: data.pressure


exports.Climate = class Climate


  insert_barometer = ->
    Gauge.create
      "barometer":
        title:    ""
        scale:    "S1":
          presets:   ["Room_Temperature", "Ticks_Left"]
          label:  "P"
          unit:   "mbar"
          v0:     960
          v1:     1060
          track:  color: "none"
          tick:
            v0:   960
            v1:   1060
            divisions:  10
          subtick:
            v0:   960
            v1:   1060
            divisions:  50
          number:
            v0:     960
            v1:     1060
            divisions: 5
          type:     "horseshoe"
          quantity:
            "P0":
              indicator:
                "Needle0":
                  type:       "pointer"
                  shape:      "needle1"
