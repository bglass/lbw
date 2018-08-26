{Gauge} = require '/home/boris/work/glass-gauge/src/coffee/gauge.coffee'

exports.House = class House

  setup: ({rooms, target}) ->
    for number, name of rooms
      update number, "name", name
      update number, "number", number
      link_to number, target
    insert_barometer()

  select = (room, subclass) ->
    $(".roomWrap#R#{room} .#{subclass}")

  link_to = (room, target) ->
    $("#R"+room).click(target)

  update = (room, subclass, text) ->
    select(room, subclass).empty().append text

  relative_temperature = (v) ->
    v0 = 10
    v1 = 30
    return  (v-v0) / (v1-v0)

  limited_relative = (v) ->
    rl = relative_temperature v
    rl = 0 if rl<0
    rl = 1 if rl>1
    return rl

  temp2color = (v, a=1) ->
    rl = limited_relative v
    return "hsla(#{200*(1-rl)}, 80%, 50%, #{a})"

  update_temperature = (room, number, unit) ->
    update room, "temperature", number.toFixed(1)
    update room, "unit", unit
    set_color room, temp2color number

  set_color = (room, color) ->
    select(room, "room").css('background-color', color);


  weather: (data) ->
    dir   = data.wind.direction
    speed = Math.log(1 + data.wind.speed)

    $("#wind #pointer")[0].setAttribute "transform", "rotate(#{dir}) scale(#{speed * 2})"
    Gauge.setValue barometer: P0: data.pressure

    west_east = if (dir < 180) then -1 else 1
    for flag in $(".windvane")
      flag.setAttribute("points", "0,-0.5 #{west_east * speed/5},-0.4 0 -0.3");

    color = temp2color data.temperature, 0.1
    $("#House .background").css 'background-color', color

    color = temp2color data.temperature
    $("#R2201").css 'background-color', color

    $("#R2201 .temperature").empty().append data.temperature
    $("#R2201 .unit").empty().append "°C"

  receive: (payload) ->
    if payload.name
      room = payload.name.substr 1,3
      dot  = payload.name.substr 4,1
      rest = payload.name.substr 4

      switch payload.dpst
        when "9-1" # Temperature [dC]
          if payload.number and (dot == '.' or rest.length == 0)
            update_temperature room, payload.number, payload.unit



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
