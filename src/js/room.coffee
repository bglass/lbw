exports.Room = class Room

  @store   = {}
  @current = ""

  constructor: (@data) ->
    Room.store[@data.number] = @

  @find: (id) ->
    @store[id]

  @create: (rooms) ->
    for number, name of rooms
      new Room
        number: number
        name:   name

  drop1st = (str) ->
    str.substr 1


  @goto: (evt) ->
    $("#btnRooms").click();
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.update_page()
    Room.current = number

  @receive: (payload) ->
    key  = payload.name.substr 1,3
    if payload.number  and (room = Room.find key)
      room.receive (payload)

  receive: (payload) ->
    room = payload.name.substr 1,3
    dot  = payload.name.substr 4,1
    rest = payload.name.substr 4

    switch payload.dpst
      when "9-1" # Temperature [dC]
        @data.temperature = payload.number.toFixed 1
        @data.unit        = payload.unit

    if room == Room.current
      @update_page()




  update_page: ->
    for key, value of @data
      $("#Rooms .#{key}").text value
