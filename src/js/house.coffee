exports.House = class House

  constructor: (rooms) ->

    @svg = House.Gauge.get("house")
    for number, details of rooms
      new House.Room @svg, number, details

    @setup

  setup: ->
    House.Room.insert_temperature_gauge()
    House.Room.insert_valve_gauge()

  @configure: ({gauge, room}) ->
    House.Gauge  = gauge
    House.Room = room
