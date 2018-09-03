{merge, addClass}    = require './helpers.coffee'


exports.SVG = class SVG

  @store = {}

  constructor: (@id, @node)->

  @add_svg: (id, xywh) ->
    target = document.getElementById(id)
    tag = document.createElementNS(ns, "svg")
    node = target.appendChild(tag)
    node.setAttribute "viewBox", xywh.join(" ")
    node.setAttribute "id", id
    svg = new SVG(id, node)
    svg.defs = svg.add_defs()
    return svg

  ns = "http://www.w3.org/2000/svg"

  visibility: (value) ->
    @node.style.visibility = value;


  add_element: (id, type, attributes) ->
    tag = @new_tag id, type, attributes
    if id?.length
      new SVG(id, tag)

  new_tag: (id, type, attributes) ->
    tag = document.createElementNS(ns, type)
    if id?.length
      tag.setAttribute "id", id
    for key, value of attributes
      tag.setAttribute key, value
    @node.appendChild(tag)


  add_text: (id, content, attributes) ->
    svg = @add_element id, "text", attributes
    svg.node.textContent = content
    return svg

  add_path: (id, shape, attributes) ->
    tag = @new_tag id, "path", attributes
    svg = new Path(id, tag)
    svg.node.setAttribute "d", shape
    svg.node.setAttribute "pathLength", 1.0
    svg.node.setAttribute "fill", "none"
    svg.shape = shape
    return svg

  add_group: (id, attributes = {}) ->
    @add_element id, "g", attributes

  derive_path: (id, template, attributes) ->
    @add_path id, template.shape, attributes

  new_path: (id, config, attributes) ->
    path = @add_path id, ( Path[config.type](config) ), attributes
    Path.store[id] = path
    return path

  add_polygon: (id, attributes) ->
    @add_element id, "polygon", attributes

  add_defs: ->
    @add_element "defs", "defs", {}

  add_marker: (id, attributes) ->
    @add_element id, "marker", attributes


  follow_path: (target) ->
    @add_element "motion"+@id, "animateMotion",
      begin:            "indefinite"
      rotate:           "auto"
      dur:              "5s"
      keyTimes:         "0;1"
      keyPoints:        "0;0"
      calcMode:         "linear"
      fill:             "freeze"
      path:             target.shape

  attr_str = (attributes) ->
    attr = []
    for key, value of attributes
      attr.push "#{key}='#{value}'"
    return attr.join(" ")

  xml = (tag, content, attributes) ->
    return "<#{tag} #{attr_str attributes}>#{content}</#{tag}>"

  update: (attributes) ->
    for key, value of attributes
      @node.setAttribute key, value



  draw_tick: (data) ->
    p1 = data.path.offset data.x, data.offset1
    p2 = data.path.offset data.x, data.offset2
    @add_element "", "line",
      x1:               p1.x
      y1:               p1.y
      x2:               p2.x
      y2:               p2.y
      stroke:           data.color
      "stroke-width":   data.thickness


  beginElement: ->
    @node.beginElement()

  setText: (str) ->
    @node.textContent = str

  setAttr: (attr, value) ->
    @node.setAttribute attr, value

  make_draggable: (path_id, quantity_id) ->
    @node.classList.add "draggable"
    @node.dataset.quantity = quantity_id
    @node.dataset.path     = path_id


  addClass:    (name) -> addClass    @node, name
  removeClass: (name) -> removeClass @node, name

  findById: (id) ->
    @node.getElementById id

  opacity: (alpha) ->
    @node.setAttribute "opacity", alpha


# =============================================================================

class Path extends SVG

  # project mouse coordinates onto this path.
  # Use t0 as starting point.
  project: (t0, mouse) ->

    t = t0

    p0  = @position t0
    d0 = distance p0, mouse

    dt_min = 0.0001
    dt     = 0.01
    sign   = if t0 > 0.5 then -1 else 1
    max_it = 100

    while (dt > dt_min) and (max_it > 0)
      max_it -=1
      t  += sign*dt

      if t > 1
        if @cyclic
          t -= 1
        else
          return 1
      else if t < 0
        if @cyclic
          t += 1
        else
          return 0

      p   = @position t
      d1  = distance p, mouse

      if d0 < d1
        dt = dt / 2
        sign = -sign
      d0 = d1
    return t


  distance = (a, b) ->
    dx = b.x - a.x
    dy = b.y - a.y
    Math.sqrt(dx*dx + dy*dy)

  position: (distance) ->
    @node.getPointAtLength distance * @node.getTotalLength()

  animate_dash: ->
    @add_element "dashani"+@id, "animate",
      attributeName:    "stroke-dashoffset"
      attributeType:    "XML"
      begin:            "indefinite"
      dur:              "2s"
      calcMode:         "linear"
      fill:             "freeze"

  @horizontal: (data) ->
    x0 = data.w * .1
    x1 = data.w * .9
    y  = data.h / 2
    "M #{x0} #{y} L #{x1} #{y}"

  @vertical:  (data) ->
    y0 = data.h * .1
    y1 = data.h * .9
    x  = data.w / 2
    "M #{x} #{y1} V #{y0}"

  @semi_arc: (data) ->
    r  = data.w*.25
    mx = data.w*.5;       my = data.h*.5
    sx = mx-r;            sy = my
    "M #{sx} #{sy} a #{r} #{r} 0 0 1 #{2*r} #{0}"


  @circular_arc: (data) ->
    r  = data.w*.6
    mx = data.w*.9;       my = data.h*.9
    sx = mx-r;            sy = my
    "M #{sx} #{sy} a #{r} #{r} 0 0 1 #{r} #{-r}"

  @horseshoe: (data) ->
    r  = data.w*.3
    sx = data.w*.3;            sy = data.h*.7
    ex = data.w*.7;            ey = data.h*.7
    "M #{sx} #{sy} A #{r} #{r} 0 1 1 #{ex} #{ey}"

  @circle:  (data) ->
    r  = data.w*.3
    x12 = data.w*.5;         y12 = data.h*.2
    x06 = data.w*.5;         y06 = data.h*.8
    "M #{x12} #{y12} " +
    "A #{r} #{r} 0 1 1 #{x06} #{y06} " +
    "A #{r} #{r} 0 1 1 #{x12} #{y12} "

  offset: (distance, crosstrack) ->
    t  = distance
    c  = crosstrack

    arccos  = Math.acos
    pi      = Math.PI
    l  = @node.getTotalLength()
    dt = 1e-2

    if t >   dt   then t0 = t-dt else t0 = t
    if t < (1-dt) then t1 = t+dt else t1 = t

    p  = @node.getPointAtLength t  * l
    p0 = @node.getPointAtLength t0 * l
    p1 = @node.getPointAtLength t1 * l

    dx = p1.x - p0.x
    dy = p1.y - p0.y

    r   = Math.sqrt( dx*dx + dy*dy )

    phi = if dy<0
            -arccos dx/r
          else
            arccos dx/r

    tx = dx/r
    ty = dy/r

    nx = -ty
    ny =  tx

    ox = p.x + c * nx
    oy = p.y + c * ny

    {x: ox, y: oy, phi: 180*phi/pi}






# =============================================================================
