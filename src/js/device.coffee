exports.Device = class Device
  @store        = {}
  @ko_callback  = {}
  @find:        (x)   ->    Device.store[x]

  constructor: ({@name, @room, @channels}) ->
    Device.store[@name]   = @
    @timestamp            = 0
    @value                = 0
    @subscribers          = []
    @subname              = subname @channels

  subname = (channels) ->
    for c, data of channels
      return data.subname

  @discover: ({ga_catalog}) ->

    tree = analyze ga_catalog
    # console.log "tree", tree
    create_devices tree

  @find_type: (room, type) ->
    devices = []
    for name, device of Device.store
      devices.push device if device["is"+type]? and device.room == room
    return devices

  subscribe: (subscriber) ->
    @subscribers.push subscriber

  refresh: ->
    # console.log "refresh", @name, @channels, @subscribers
    for subscriber in @subscribers
      subscriber @value, @timestamp

  @receive: (payload) ->
    # console.log "receive", payload
    if callbacks = Device.ko_callback[payload.ga]
      for cb in callbacks
        cb payload.number, payload.timestamp

  create_devices = (tree) ->
    for trade, rooms of tree
      for room, devices of rooms
        for name, data of devices
          config = { name: name, room: room, channels: data }

          device = (
            switch trade
              when "L", "B"
                if data.brightness      then    new Dimmer  config
                else                            new Light   config
              when "W"                  then    new Socket  config
              when "T"                  then    new TSensor config
              when "H"                  then    new HSensor config
              when "S"                  then    new Setpoint config
            # when "G" # gate car / pedestrian
            # when "J" # jalousie
            # when "P"
            #   create_switches rooms
            # when "V"
            #   create_valves rooms
            # when "X"  # ignore
            )
          device.subscribe_channels()   if device



  analyze = (ga_catalog) ->
    tree = {}
    for ga, d of ga_catalog
      type  = ko_type d
      trade = d.trade
      room  = d.room
      first = d.subname
      common = trade + room + first

      t = tree[trade]   ?= {}
      r = t[room]       ?= {}
      c = r[common]     ?= {}
      k = c[type]       ?= {}

      k.ga        = ga
      k.dpt       = d.dpt
      k.subname   = d.subname
    return tree

  ko_type = (d) ->
    switch d.trade
      when "L", "B", "W", "G", "P"
        if d.szene
          "szene"
        else if d.setpoint and d.status
          "reply"
        else if d.value
          "brightness"
        else if d.status
          "status"
        else if d.dimmer
          "dimming"
        else
          "switch"
      when "t"
        if d.setpoint and d.status
          "reply"
        else if d.setpoint
          "setpoint"
      when "H", "T"
        if d.status
          "status"
        else
          "sensor"
      when "V"
        if d.status
          "status"
        else
          "valve"
      else
        "default"

  set = (device) -> (value, timestamp) ->
    if value?
      device.set value, timestamp
    else
      console.warn "Device.set: undefined value", device.name

  set: (@value, @timestamp) ->
    # console.log "dev rx", @name, @value
    @refresh()

  subscribe_channels: ->
    for channel, data of @channels
      callback = (
        switch channel
          when "switch", "brightness", "status", "reply", "sensor", "valve"
            set @
          # when "dimming"
          # when "szene"
          else
            false
            )
      if callback
        Device.ko_callback[data.ga] ?= []
        Device.ko_callback[data.ga].push callback

# ===============================================================

exports.Sensor = class Sensor extends Device

# ------------------------------------------------------------------

exports.TSensor = class Setpoint extends Sensor

# ------------------------------------------------------------------

exports.TSensor = class TSensor extends Sensor
  istsensor: true

# ------------------------------------------------------------------
exports.HSensor = class HSensor extends Sensor
  ishsensor: true

# ------------------------------------------------------------------

exports.Switch = class Switch extends Device

  binary: ->
    return if @value then true else false


# ------------------------------------------------------------------

exports.Socket = class Socket extends Switch
  issocket: true

# ------------------------------------------------------------------

exports.Light = class Light extends Switch
  islight: true

# ------------------------------------------------------------------

exports.Dimmer = class Dimmer extends Light
  isdimmer: true

  brightness: ->
    return (
      if typeof @value == 'boolean'
        if @value then 100 else 0
      else
        @value
        )

# ------------------------------------------------------------------
