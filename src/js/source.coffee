class Source

  constructor: ->
    @subscribers      = []
    @data = {}


  subscribe: (subscriber) ->
    @subscribers.push subscriber

  refresh: ->
    for subscriber in @subscribers
      subscriber @data

exports.Weather = class Weather extends Source

  constructor: ->
    super()
    Weather.singleton = @
    @data = {
      timestamp:    0
      temperature:  0
      pressure:     0
      wind:
        direction:  0
        speed:      0
      }

  # @receive: (payload) ->
  #   Weather.singleton.receive payload

  receive: (payload) =>
    @data.wind.direction = payload.winddirection
    @data.wind.speed     = payload.windspeed
    @data.temperature    = payload.tempc
    @data.pressure       = payload.pressure
    @data.text           = payload.weather
    @data.icon           = payload.icon
    @data.timestamp      = Date.now()
    @refresh()

exports.Sheep = class Sheep extends Source

  receive: (payload) =>
    @data[payload.channel.join("/")] = payload.value
    @refresh()
