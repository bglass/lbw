Gauge = (require "glass-gauge").Gauge
{KNX}   = require './knx.coffee'

exports.Room = class Room

  @store   = {}
  @current = ""

  constructor: (@data) ->
    Room.store[@data.number] = @

  @find: (id) ->
    @store[id]

  @create: (rooms) ->
    insert_temperature_gauge()
    for number, name of rooms
      new Room
        number: number
        name:   name

    # exceptions
    @store["201"] = @store["202"]


  drop1st = (str) ->
    str.substr 1


  @goto: (evt) ->
    $("#btnRooms").click();
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.switch()
    Room.current = number

  @receive: (payload) ->
    key  = payload.name.substr 1,3

    if room = Room.find key
      room.receive (payload)

  receive: (payload) ->
    room = payload.name.substr 1,3
    dot  = payload.name.substr 4,1
    rest = payload.name.substr 4

    switch payload.dpst
      when "9-1" # Temperature [dC]
        @data.temperature = payload.number.toFixed 1
        @data.unit        = payload.unit

      # when "1-1" # Switch
        # console.log "pay?", payload, payload.number

    if room == Room.current
      @update_page()

  switch: ->
    for key, value of @data
      $("#Rooms .#{key}").text value

    tsensors = KNX.tsensor_names @data.number
    console.log "tsensors", tsensors
    if tsensors.length > 0
      Gauge.setValue "RoomT": {T: @data.temperature}
      Gauge.show "RoomT"
    else
      Gauge.hide "RoomT"


  update: ->


    # $("#Rooms .S").text "Temperatures: " + KNX.list_temperature_sensors @data.number



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
          quantity: "T":
            indicator:
              "Bar":      type: "bar"
              "Digital":  type: "digital"
              "Color":
                type:       "color"
                target:     "Bar"
                attribute:  "stroke"
