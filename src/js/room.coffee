# Gauge   = (require "glass-gauge").Gauge
{Gauge} = require '/home/boris/work/glass-gauge/src/coffee/gauge.coffee'

icon    = require '../html/icons.pug'
sliders = require '../html/rooms/light_sliders.pug'
iconbar = require '../html/icon/bar.pug'
icon    = require '../html/icon/icon.pug'

exports.Room = class Room

  @current = ""
  @store = {}
  @find:  (x) ->    Room.store[x]
  @get:   (x) ->    if y = Room.find x then y else new Room(x)

  constructor: (@number) ->
    Room.store[@number] = @
    @subscribers        = []
    @data =
      temperature: 0
      brightness:  0
      motion:      false
      valve:       0

  @create: (rooms) ->
    Room.rooms = rooms
    insert_temperature_gauge()
    insert_valve_gauge()

  @set_find_devices: (f) ->
    Room.find_devices = f

  select = (room, subclass) ->
    $(".roomWrap#R#{room} .#{subclass}")

  link_to = (room, target) ->
    $("#R"+room).click(target)

  update_data_cell = (room, subclass, text) ->
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

  set_color = (room, color) ->
    select(room, "room").css('background-color', color);


  @setup: (payload) ->
    for number, name of Room.rooms
      room = Room.get number
      room.setup(name)

  setup: (@name) ->
    @devices = find_devices @number
    @furnish_the_house()
    subscribe_to @devices, @number
    @refresh()

  furnish_the_house: ->
    update_data_cell @number, "name", @name
    update_data_cell @number, "number", @number
    link_to @number, goto

    if m = @devices.motions[0]
      insert_icon  "#R#{@number} .motion",  m.name, "feet"






  find_devices = (room) ->
    sockets:        Room.find_devices room, "socket"
    tsensor:        Room.find_devices room, "tsensor"
    tsetpoint:      Room.find_devices room, "tsetpoint"
    valves:         Room.find_devices room, "valve"
    lights:         Room.find_devices room, "light"
    lights_dimmed:  Room.find_devices room, "dimmer"
    motions:        Room.find_devices room, "motion"

  subscribe_to = (devices, room) ->
    for socket in devices.sockets
      socket.subscribe update_color("stroke", "socket"+socket.name)
    for tsensor, i in devices.tsensor
      tsensor.subscribe update_gauge(room, "RoomT", "T"+i )
      tsensor.subscribe update_summary_temperature(room) if i==0
    for tsetpoint, i in devices.tsetpoint
      tsetpoint.subscribe update_gauge(room, "RoomT", "Tset"+i )
    for valve, i in devices.valves
      valve.subscribe update_gauge(room, "RoomV", "V"+i)
    for light in devices.lights
      light.subscribe update_color("stroke", "bulb"+light.name)
    for light in devices.lights_dimmed
      id = "Dim" + light.name
      light.subscribe update_value(id)
    for motion in devices.motions
      uv = update_visibility("#feet"+motion.name)
      motion.subscribe uv
      uv = update_visibility(".motion svg#"+motion.name)
      motion.subscribe uv


  subscribe: (subscriber) ->
    @subscribers.push subscriber

  switch_to: ->


    Room.current = @number

    # static text
    $("#Rooms .name").text @name
    $("#Rooms .number").text @number

    # temperature gauge
    if not @devices.tsensor?.length > 0
      Gauge.hide "RoomT"
      Gauge.hide_indicator "RoomT", "Needle1"
    else
      Gauge.show "RoomT"
      if @devices.tsensor.length == 1
        Gauge.hide_indicator "RoomT", "Needle1"
      else
        Gauge.show_indicator "RoomT", "Needle1"


    # setpoints
    if @devices.tsetpoint?.length > 0
      Gauge.show_indicator "RoomT", "Setpoint"
    else
      Gauge.hide_indicator "RoomT", "Setpoint"

    # valves
    if @devices.valves?.length > 0
      # console.log "show valve", @devices.valves[0].value, @devices.valves[0].timestamp
      Gauge.show "RoomV"
    else
      # console.log "hide valve"
      Gauge.hide "RoomV"

    # lights and sockets
    insert_icons  "#Rooms .SE", @devices.sockets,      "socket"
    insert_icons  "#Rooms .NE", @devices.lights,      "bulb"
    insert_dimmer "#Rooms .E",  @devices.lights_dimmed
    insert_icons  "#Rooms .W",  @devices.motions, "feet"

    @refresh()

  refresh: ->
    for type, devices of @devices
      for device in devices
        device.refresh()
    for subscriber in @subscribers
      subscriber @data

  drop1st = (str) -> str.substr 1

  goto = (evt) ->
    $("#btnRooms").click();
    history.pushState {}, "Rooms", "#Rooms"
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.switch_to()


  # also see https://codepen.io/kunukn/pen/pgqvpQ for a different, very nice design

  update_color = (attribute, element_name) -> (raw_value, timestamp) ->
    console.log "uc", @name
    if typeof raw_value == 'boolean'
      value = if raw_value then 60 else 0
    else
      value = raw_value * 0.6
    if element = $("#"+element_name)[0]
      element.setAttribute attribute, "hsl(50, 100%, #{value}%)"

  update_visibility = (element_name) -> (visibility, timestamp) ->
    for e in $(element_name)
      e.setAttribute "visibility", (if visibility then "visible" else "hidden")

  update_text  = (element) -> (value, timestamp) ->
    $element.empty().append value.toFixed(1)

  update_value = (element_name) -> (value, timestamp) ->
    if element = $("#"+element_name)[0]
      element.value = value

  update_gauge = (room, gauge, quantity) -> (value, timestamp) ->
    if room == Room.current
      # console.log "UG", room, gauge, quantity, value, timestamp
      data = {}
      data[gauge] = {}
      data[gauge][quantity] = {value: value, timestamp: timestamp}
      Gauge.setValue data

  update_summary_temperature = (room) -> (value, timestamp) ->
    update_data_cell room, "temperature", value.toFixed(1)
    update_data_cell room, "unit", "°C"
    set_color room, temp2color value


  insert_dimmer = (selector, list) ->
    # names = list.map (x) -> "Dim" + x.name
    $(selector).empty().append (sliders items: list)

  insert_icons = (selector, list, shape) ->

    cell = $(selector).empty()
    # console.log "ii", shape, list
    src = iconbar(shape: shape, items: list)
    cell.append src

  insert_icon = (selector, id, shape) ->
    cell = $(selector).empty()
    src = icon(shape: shape, id: id)
    cell.append src

  @outdoor: (data) ->
    dir   = data.wind.direction
    speed = Math.log(1 + data.wind.speed)

    $("#wind #pointer")[0].setAttribute "transform", "rotate(#{dir}) scale(#{speed * 2})"

    northerly = Math.cos(dir*Math.PI/180)
    westerly  = - Math.sin(dir*Math.PI/180)

    flag = $(".windvane")
    flag[0].setAttribute("points", "0,-0.5 #{northerly * speed/3},-0.4 0 -0.3");
    flag[1].setAttribute("points", "0,-0.5 #{westerly * speed/3},-0.4 0 -0.3");

    color = temp2color data.temperature, 0.1
    $("#House .background").css 'background-color', color

    color = temp2color data.temperature
    $("#R2201").css 'background-color', color

    $("#R2201 .temperature").empty().append data.temperature
    $("#R2201 .unit").empty().append "°C"

    iconurl = "http://openweathermap.org/img/w/#{data.icon}.png"
    $('.weather img').attr 'src', iconurl

    console.log "wrx"



  insert_temperature_gauge = ->
    Gauge.create
      "RoomT":
        title:    ""
        scale:    "S1":
          number:
            rotate: 0
            divisions: 4
          type:     "semi_arc"
          presets:   ["Room_Temperature", "Ticks_Left"]
          quantity:
            "T0":
              indicator:
                "Bar":      type: "bar"
                "Digital":  type: "digital"
                "Color":
                  type:       "color"
                  target:     "Bar"
                  attribute:  "stroke"
                "Needle0":
                  type:       "pointer"
                  shape:      "needle1"
            "T1":
              indicator:
                "Needle1":
                  type:       "pointer"
                  shape:      "needle1"
            "Tset0":
              indicator:
                "Setpoint":
                  type:   "pointer"
                  shape:  "right"
                  color:  "blue"
                  offset: -50

  insert_valve_gauge = ->
    Gauge.create
      "RoomV":
        title:    ""
        scale:    "S1":
          type:     "vertical"
          v0:     0
          v1:     100
          quantity:
            "V0":
              indicator:
                "Bar":
                  type: "bar"
                  color: "red"
                "Digital":  type: "digital"
