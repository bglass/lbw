{merge}         = require './helpers.coffee'
{Scale}         = require './scale.coffee'
{SVG}           = require './svg.coffee'
{settings}      = require './presets.coffee'
{events}        = require './event.coffee'


export class Gauge

  @store = {}

  @create: (config) ->
    gauges = []
    for gauge_id, cfg of config
      console.log "Gauge:", gauge_id, cfg
      gauges.push (new Gauge(gauge_id, cfg))
    return gauges

  constructor: (@id, config) ->
    Gauge.store[@id] = @

    console.log "Gauge construct", @id, config
    @config = settings("gauge", config)

    @svg = SVG.add_svg @id, [0, 0, @config.width, @config.height]
    events(@, @svg)

    @elements = merge(
      @draw_elements()
      @create_subelements()
    )


  @get: (id) ->
    return SVG.get id

  create_subelements: ->
    scales: Scale.create @config.scale, @data()

  draw_elements: ->
    title:  @draw_title()

  draw_title: ->
    @svg.add_text @id, @config.title,
      class:                "title"
      "alignment-baseline": "middle"
      "text-anchor":        "start"
      "font-size":          100
      "font-weight":        "normal"
      x:                    0
      y:                    @config.height * .1

  data: ->
    title:      @config.title
    w:          @config.width
    h:          @config.height
    svg:        @svg

  @setValue: (updates) ->
    for id, update of updates
      if @store[id]
        @store[id].setValue update
      else
        console.error "Undefined Gauge id: " + id

  setValue: (update) ->
    for scale_id, scale of @elements.scales
      scale.setValue @data(), update

  stepValue: (qty_id, direction) ->
    for scale_id, scale of @elements.scales
      scale.stepValue qty_id, direction

  getRelativeLimited: (qty_id) ->
    rl = false
    for scale_id, scale of @elements.scales
      rlx = scale.getRelativeLimited qty_id
      rl = rlx if rlx
    return rl


  getRelative: (qty_id) ->
    r = false
    for scale_id, scale of @elements.scales
      rx = scale.getRelative qty_id
      r = rx if rx
    return r

  setRelative: (qty_id, r) ->
    for scale_id, scale of @elements.scales
      scale.setRelative qty_id, r

  @show: (id) ->
    @store[id].svg.visibility "visible"

  @hide: (id) ->
    @store[id].svg.visibility "hidden"

  @show_indicator: (gid, id) ->
    @store[gid].indicator_visibility id, "visible"

  @hide_indicator: (gid, id) ->
    @store[gid].indicator_visibility id, "hidden"

  indicator_visibility: (id, visibility) ->
    for scale_id, scale of @elements.scales
      scale.indicator_visibility id, visibility
