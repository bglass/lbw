{merge, filter, round}  = require './helpers.coffee'
{Quantity}              = require './quantity.coffee'
{settings}      = require './presets.coffee'

# {Horizontal}    = require './path.coffee'

# ============================================================

exports.Scale = class Scale


  @create: (config, data) ->
    scale = {}
    for scale_id, cfg of config
      scale[scale_id] = new Scale(scale_id, cfg, data)
    return scale

  constructor: (@id, config, data) ->
    @config = settings("scale", config)
    @elements = merge(
      @draw_elements(data)
      @create_subelements(data)
    )


  create_subelements: (data) ->
    quantities:   Quantity.create @config.quantity, @refine(data)

  refine: (data) ->
    barWidth:         @config.barWidth
    unit:             @config.unit
    v0:               @config.v0
    v1:               @config.v1
    path:             @path_template
    svg:              data.svg
    w:                data.w
    h:                data.h
    cyclic:           @config.cyclic

  draw_elements: (data) ->
    template:   @draw_template  data
    ticks:      @draw_ticks     data
    track:      @draw_track    data
    label:      @draw_label    data
    scaling:    @draw_scaling  data
    segments:   @draw_segments data

  draw_scaling: (data) ->
    cfg = @config.number
    for v,i in tick_values cfg


      r = (v - @config.v0) / (@config.v1 - @config.v0)
      p = @path_template.offset(r, cfg.offset)

      angle = if cfg.rotate? then cfg.rotate else p.phi

      group = data.svg.add_group @id+"G"+i,
        transform:               "rotate (#{angle} #{p.x} #{p.y})"

      number = group.add_text @id+"S"+i, round(v,1),
        class:                "scaling"
        "alignment-baseline": "middle"
        "text-anchor":        "middle"
        "font-size":          100
        "font-weight":        "normal"
        x:                    p.x
        y:                    p.y

  draw_ticks: (data) ->
    main:   @draw_tick_flavor data, @config.tick, "tick"
    sub:    @draw_tick_flavor data, @config.subtick, "subtick"

  draw_tick_flavor: (data, cfg, id_prefix) ->

    group = data.svg.add_group id_prefix + @id

    for v,i in tick_values cfg
      r = (v - @config.v0) / (@config.v1 - @config.v0)

      group.draw_tick
        x:          r
        offset1:    cfg.offset1
        offset2:    cfg.offset2
        thickness:  cfg.thickness
        color:      cfg.color
        path:       @path_template
    return group

  draw_template: (data) ->
    @path_template =
      data.svg.new_path "template"+@id, (merge @config, data),
          class:                "template"
          visibility:           "hidden"
    @path_template.cyclic = @config.cyclic
    return @path_template

  draw_track: (data) ->
    data.svg.new_path "track"+@id, (merge @config, data),
        class:                "track"
        "stroke-width":       @config.barWidth
        stroke:               @config.track.color

  relative_value = (data, value) ->
    (value - data.v0) / (data.v1 - data.v0)

  draw_segments: (data) ->
    if @config.track.segments
      @config.track.segments.map (segment, i) =>
        [color, start, stop] = segment.split(" ")

        a = relative_value @config, start
        b = relative_value @config, stop

        if a < 0 then a = 0
        if b > 1 then b = 1

        data.svg.derive_path @id+"segment"+i, @path_template,
          stroke:               color
          "stroke-width":       @config.barWidth
          "stroke-dasharray":   "#{b-a} #{1+a-b}"
          "stroke-dashoffset":  -a

  tick_definition = (tick) ->
    a = tick.thickness
    n = tick.divisions
    b = (1 - a*(n+1) ) / n
    return "#{a} #{b}"

  tick_values = (tick) ->
    n = tick.divisions
    [0..n].map (i) ->
      tick.v0 + i/n*(tick.v1-tick.v0)



  draw_label: (data) ->
    data.svg.add_text @id, @config.label,
      class:                "label"
      "alignment-baseline": "middle"
      "text-anchor":        "start"
      "font-size":          100
      "font-weight":        "normal"
      x:                    0
      y:                    data.h * .8


  setValue: (data, update) ->
    for qty, value of update
      if value?
        if @elements.quantities[qty]
          @elements.quantities[qty].setValue @refine(data), value
        else
          console.error "Undefined Quantity id: " + qty
      else
        console.error "Gauge refuses to set quantity '#{qty}' to undefined."


  setRelative: (qty_id, r) ->
    @elements.quantities[qty_id].setRelative (@refine {}), r

  stepValue: (qty_id, direction) ->
    @elements.quantities[qty_id].stepValue (@refine {}), direction


  getRelativeLimited: (qty_id) ->
    @elements.quantities[qty_id].limited_value(@refine {})

  getRelative: (qty_id) ->
    @elements.quantities[qty_id].relative_value(@refine {})

  indicator_visibility: (id, visibility) ->
    for qty_id, qty of @elements.quantities
      qty.indicator_visibility id, visibility


# ============================================================
