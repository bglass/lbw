# Gauge   = (require "glass-gauge").Gauge
{Gauge} = require '/home/boris/work/glass-gauge/src/coffee/gauge.coffee'

{Device}=  require './device.coffee'
icon    =  require '../html/icons.pug'

sliders =  require '../html/rooms/light_sliders.pug'
iconbar =  require '../html/icon/bar.pug'

exports.Room = class Room

  @current = ""

  @store = {}
  @find:  (x) ->    Room.store[x]
  @get:   (x) ->    if y = Room.find x then y else new Room(x)

  constructor: (@number) ->
    Room.store[@number] = @

  @create: (rooms) ->
    Room.rooms = rooms
    insert_temperature_gauge()
    insert_valve_gauge()

  @setup: (payload) ->
    for number, name of Room.rooms
      room = Room.get number
      room.setup(name)


  setup: (@name) ->
    @socket          = Device.find_type @number, "socket"
    @tsensor         = Device.find_type @number, "tsensor"
    @tsetpoint       = Device.find_type @number, "tsetpoint"
    @valve           = Device.find_type @number, "valve"
    @lights          = Device.find_type @number, "light"
    @light_dimmed    = Device.find_type @number, "dimmer"

    @devices = [].concat @lights, @tsensor, @tsetpoint, @socket, @valve



    for tsensor, i in @tsensor
      tsensor.subscribe update_gauge("RoomT", "T"+i )
    for tsetpoint, i in @tsetpoint
      tsetpoint.subscribe update_gauge("RoomT", "Tset"+i )

    for light in @lights
      light.subscribe update_color("stroke", "bulb"+light.name)

    for light in @light_dimmed
      id = light.name+"Dim"
      light.subscribe update_value(id)



  switch_to: ->

    # static text
    $("#Rooms .name").text @name
    $("#Rooms .number").text @number

    # temperature gauge
    if not @tsensor?.length > 0
      Gauge.hide "RoomT"
      Gauge.hide_indicator "RoomT", "Needle1"
    else
      Gauge.show "RoomT"
      if @tsensor.length == 1
        Gauge.hide_indicator "RoomT", "Needle1"
      else
        Gauge.show_indicator "RoomT", "Needle1"

    for ko in @tsensor
      ko.refresh()
    for ko in @tsetpoint
      ko.refresh()

    # valves
    if @valve?.length > 0
      Gauge.setValue "RoomV": V: @valve[0].value

      Gauge.show "RoomV"
    else
      Gauge.hide "RoomV"

    # lights and sockets
    insert_icons  "#Rooms .SE", @socket,      "socket"
    insert_icons  "#Rooms .NE", @lights,      "bulb"
    insert_dimmer "#Rooms .E",  @light_dimmed

    @refresh()

  refresh: ->
    for device in @devices
      device.refresh()

  drop1st = (str) -> str.substr 1

  @goto: (evt) ->
    $("#btnRooms").click();
    history.pushState {}, "Rooms", "#Rooms"
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.switch_to()
    Room.current_number = number


  # also see https://codepen.io/kunukn/pen/pgqvpQ for a different, very nice design

  update_color = (attribute, element_name) -> (raw_value, timestamp) ->

    if typeof raw_value == 'boolean'
      value = if raw_value then 60 else 0
    else
      value = raw_value * 0.6
    if element = $("#"+element_name)[0]
      element.setAttribute attribute, "hsl(50, 100%, #{value}%)"

  update_text  = (element) -> (value, timestamp) ->
    $element.empty().append value.toFixed(1)

  update_value = (element_name) -> (value, timestamp) ->
    if element = $("#"+element_name)[0]
      element.value = value

  update_gauge = (gauge, quantity) -> (value, timestamp) ->
    data = {}
    data[gauge] = {}
    data[gauge][quantity] = {value: value, timestamp: timestamp}
    Gauge.setValue data


  insert_dimmer = (selector, list) ->
    $(selector).empty().append (sliders items: list)

  insert_icons = (selector, list, shape) ->

    cell = $(selector).empty()
    src = iconbar(shape: shape, items: list)
    cell.append src

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
            "V":
              indicator:
                "Bar":
                  type: "bar"
                  color: "red"
                "Digital":  type: "digital"
