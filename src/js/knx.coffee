exports.KNX = class KNX

  @store = {}
  @find:  (x)   ->    KNX.store[x]
  @get:   (x)   ->    if y = KNX.find x then y else new KNX(x)

  @findByName: (name) ->
    for ga, ko of KNX.store
      return ko if name == ko.name

  constructor: (@ga )->
    KNX.store[@ga] = @
    @timestamp = 0
    @value     = 0
    @unit      = ""
    @subscribers = []

  @ga_setup: (payload) ->
    for ga, definition of payload.ga_catalog
      ko = KNX.get ga

      for k, v of definition
        # name, dpt, trade, room, subname, dimmer, setpoint, status
        ko[k] = v

  @receive: (payload) ->
    ko = KNX.find payload.ga
    if not ko
      console.log "todo: correct name in ETS:", payload
    else
      ko.receive payload

  receive: (payload) ->
    if defined payload.number
      @value      = payload.number
      @unit       = payload.unit
      @timestamp  = payload.timestamp
      @refresh()


  defined = (x) -> not (typeof x == 'undefined')

  subscribe: (subscriber) ->
    @subscribers.push subscriber

  refresh: ->
    # console.log "refresh", @name, @subscribers
    for subscriber in @subscribers
      subscriber @value, @timestamp

  @names: (ko_list) -> names ko_list

  names = (ko_list) ->
    ko_list.map (x) -> x.name

  ko_of_room = (room_number) ->
    found = []
    for ga, ko of KNX.store
      if (ko.room == room_number)
        found.push ko
    return found

  @find_specific: (room, type) ->
    list = ko_of_room room
    list.filter (ko) -> 
      switch type
        when "tsensor"
          ko.trade == "T"     and
            not ko.setpoint   and
            not ko.status
        when "tsetpoint"
          ko.trade == "T"     and
            ko.setpoint       and
            not ko.status
        when "socket"
          ko.trade == "W"     and
            not ko.status
        when "valve"
          ko.trade == "V"     and
            not ko.status
