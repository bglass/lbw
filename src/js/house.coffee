exports.House = class House

  @configure: ({gauge, room}) ->
    House.Gauge  = gauge
    House.Room = room

  constructor: (rooms) ->

    @svg = House.Gauge.get("house")
    for number, details of rooms
      new House.Room @svg, number, details

    House.Room.insert_gauges()
