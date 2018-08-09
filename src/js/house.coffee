exports.House = class House

  setup: ({rooms, target}) ->
    for number, name of rooms
      update number, "name", name
      update number, "number", number
      link_to number, target

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

  temp2color = (v) ->
    rl = limited_relative v
    return "hsl(#{200*(1-rl)}, 80%, 50%)"

  update_temperature = (room, number, unit) ->
    update room, "temperature", number.toFixed(1)
    update room, "unit", unit
    set_color room, temp2color number

  set_color = (room, color) ->
    select(room, "room").css('background-color', color);




  receive: (payload) ->
    room = payload.name.substr 1,3
    dot  = payload.name.substr 4,1
    rest = payload.name.substr 4

    switch payload.dpst
      when "9-1" # Temperature [dC]
        if payload.number and (dot == '.' or rest.length == 0)
          update_temperature room, payload.number, payload.unit
