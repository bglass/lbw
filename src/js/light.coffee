{KNX}   =  require './knx.coffee'

exports.Light = class Light

  constructor: (@room) ->

    @light_switched  = KNX.find_specific @room, "lswitched"
    @light_dimmed    = KNX.find_specific @room, "ldimmed"
