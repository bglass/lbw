{merge}         = require './helpers.coffee'
{SVG}           = require './svg.coffee'

exports.events = (gauge, svg) ->

  node     = svg.node
  dragging  = false
  quantity = false
  path     = false
  selected = false

  startDrag = (evt) ->
    if evt.target.classList.contains('draggable')
      dragging  = evt.target
      quantity = dragging.dataset.quantity
      path     = SVG.store[dragging.dataset.path]

  endDrag = (evt) ->
    selected = dragging
    dragging = false

  drag = (evt) =>
    if dragging
      evt.preventDefault()
      rl0     = gauge.getRelativeLimited quantity
      coords  = getMousePosition evt
      t       = path.project rl0, coords
      gauge.setRelative quantity, t

  wheel = (evt) =>
    if selected
      if evt.wheelDelta > 0
        gauge.stepValue quantity, "up"
      else
        gauge.stepValue quantity, "down"

  click = (evt) =>
    if evt.target.classList.contains('draggable')
      selected = evt.target

      color = selected.getAttribute "fill"

      selected.setAttribute "stroke", color
      selected.setAttribute "stroke-width", "10"
      selected.setAttribute "fill", "white"

      quantity = selected.dataset.quantity
    else
      selected = quantity = false


  getMousePosition = (evt) =>
    CTM = node.getScreenCTM()
    return {
      x: (evt.clientX - CTM.e) / CTM.a,
      y: (evt.clientY - CTM.f) / CTM.d
    }

  node.addEventListener('mousedown',  startDrag)
  node.addEventListener('mousemove',  drag)
  node.addEventListener('mouseup',    endDrag)
  node.addEventListener('mouseleave', endDrag)
  node.addEventListener("wheel",      wheel, {passive: true})
  node.addEventListener("click",      click)
