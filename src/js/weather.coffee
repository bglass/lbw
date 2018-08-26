exports.Weather = class Weather

  constructor: ->
    Weather.singleton = @
    @subscribers      = []
    @data = {
      timestamp:    0
      temperature:  0
      pressure:     0
      wind:
        direction:  0
        speed:      0
      }

  @receive: (payload) ->
    Weather.singleton.receive payload


  receive: (payload) ->
    console.log "weather update", payload, @data

    @data.wind.direction = payload.winddirection
    @data.wind.speed     = payload.windspeed
    @data.temperature    = payload.tempc
    @data.pressure       = payload.pressure
    @data.timestamp      = Date.now()

    @refresh()

  subscribe: (subscriber) ->
    @subscribers.push subscriber

  refresh: ->
    for subscriber in @subscribers
      subscriber @data
