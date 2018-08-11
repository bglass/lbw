Gauge   = (require "glass-gauge").Gauge
{KNX}   =  require './knx.coffee'
icon    =  require '../html/icons.pug'



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

    # exceptions
    # Room.store["201"] = Room.store["202"]

  setup: (@name) ->
    @tsensor         = KNX.find_specific @number, "tsensor"
    @tsetpoint       = KNX.find_specific @number, "tsetpoint"

    @light_switched  = KNX.find_specific @number, "lswitched"
    @light_dimmed    = KNX.find_specific @number, "ldimmed"

    @socket          = KNX.find_specific @number, "socket"
    @valve           = KNX.find_specific @number, "valve"


  switch_to: ->
    # static text
    $("#Rooms .name").text @name
    $("#Rooms .number").text @number

    # temperature gauge
    if @tsensor?.length > 0
      Gauge.setValue "RoomT": T:  @tsensor[0].value
      Gauge.setValue "RoomT": Tset: 21 # @tsetpoint[0].value  # DUMMY!
      Gauge.show "RoomT"
    else
      Gauge.hide "RoomT"

    # valves
    if @valve?.length > 0
      Gauge.setValue "RoomV": V: @valve[0].value
      console.log "valve", @name, @valve[0]

      Gauge.show "RoomV"
    else
      Gauge.hide "RoomV"



    # explore

    insert_icons "socket", "#Rooms .SE", KNX.names(@socket)
    insert_icons "bulb",   "#Rooms .NE", KNX.names(@light_switched)

    # $("#Rooms .NE").empty().append  "LS: #{KNX.names @light_switched}"
    $("#Rooms .E").empty().append   "LD: #{KNX.names @light_dimmed}"
    # $("#Rooms .SE").empty().append  "socket: #{KNX.names @socket}"
    $("#Rooms .SW").empty().append  "valve: #{KNX.names @valve}"



  # update: ->
  #
  #   $("#Rooms .S").text "Temperatures: " + @temperature 0


  drop1st = (str) -> str.substr 1

  @goto: (evt) ->
    $("#btnRooms").click();
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.switch_to()
    Room.current_number = number

  @receive: (payload) ->
    if ko = KNX.find payload.ga
      if ko.room == Room.current_number
        if room = Room.find ko.room
          room.receive payload

  receive: (payload) ->

    console.log "room #{@name} received update:", payload

    # temperature gauge



    #cell_name
    # switch payload.dpst
    #   when "9-1" # Temperature [dC]
    #     @data.temperature = payload.number.toFixed 1
    #     @data.unit        = payload.unit
    #
    #   # when "1-1" # Switch
    #     # console.log "pay?", payload, payload.number
    #
    # if room == Room.current
    #   @update_page()

  insert_icons = (shape, selector, list) ->

    cell = $(selector).empty()
    for name in list
      cell.append icon(shape: shape)
      cell.append name



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
            "T":
              indicator:
                "Bar":      type: "bar"
                "Digital":  type: "digital"
                "Color":
                  type:       "color"
                  target:     "Bar"
                  attribute:  "stroke"
            "Tset":
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
