exports.KNX = class KNX

  @ga_setup: (payload) ->

    KNX.ko = {}

    for k, v of payload
      # names, dpts, trades, rooms, subnames, specials
      KNX.ko[k] = v

    KNX.ko.timestamp = {}
    KNX.ko.value     = {}
    KNX.ko.unit      = {}

    KNX.ko.setpoint = {}
    KNX.ko.status = {}
    KNX.ko.dimmer = {}
    for ga, special of KNX.ko.specials
      KNX.ko.status[ga]   = true       if /\?/.test special
      KNX.ko.setpoint[ga] = true       if /=/.test  special
      KNX.ko.dimmer[ga]   = true       if /~/.test special

  @receive: (payload) ->
    ga = payload.ga
    KNX.ko.value[ga]      = payload.room_number
    KNX.ko.unit[ga]       = payload.unit
    KNX.ko.timestamp[ga]  = payload.timestamp

  names = (ga_list) ->
    ga_list.map (x) -> KNX.ko.names[x]


  list_ga_of = (room_number) ->
    found = []
    for ga, number of KNX.ko.rooms
      if (number == room_number)
        found.push ga
    return found

  tsensors = (room) ->
    list = list_ga_of room
    list.filter (x) -> 
      KNX.ko.trades[x] == "T"     and
        not KNX.ko.setpoint[x]    and
        not KNX.ko.status[x]

  tsetpoints = (room) ->
    list = list_ga_of room
    list.filter (x) -> 
      KNX.ko.trades[x] == "T"     and
        KNX.ko.setpoint[x]        and
        not KNX.ko.status[x]

  @tsetpoint_names: (room) ->  names( tsetpoints room)
  @tsensor_names:   (room) ->  names( tsensors   room)





    # for ga in payload
    #   name = ga.col1
    #
    #   if typeof name is 'string'
    #
    #     regex = /(\w)(\d\d\d)\.*([\w\d]*)([~=\?]*)/
    #     if match =  regex.exec name
    #       type    = match[1]
    #       number  = match[2]
    #       unit    = match[3]
    #       special = match[4]



        #
        # if room = Room.find key
        #
        #   switch type
        #     when "T"
        #       switch rest
        #         when "=", "=?"
        #           room.ko.setpoint.push name
        #         else
        #           room.ko.temperature.push name
        #     when "L"
        #       console.log name
        #
