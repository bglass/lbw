icon    = require '../html/icons.pug'
sliders = require '../html/rooms/light_sliders.pug'
iconbar = require '../html/icon/bar.pug'
icon    = require '../html/icon/icon.pug'

exports.Room = class Room

  # Gauge = false

  @current = ""
  @store = {}
  @find:  (x) ->    Room.store[x]
  @get:   (x) ->    if y = Room.find x then y else new Room(x)

  @configure: ({gauge}) ->
    Room.gauge = gauge

  constructor: (@house, @number, details) ->
    Room.store[@number] = @
    @subscribers        = []
    @data =
      temperature: 0
      brightness:  0
      motion:      false
      valve:       0
    @setup details

  setup: ([@name, @floor, @x]) ->
    @refresh()
    @draw()

  @receive_group_adress_catalog: (payload) ->
    for number, details of Room.store

      room = Room.get number
      room.setup_group_address(details.name)

  setup_group_address: (@name) ->

    if @devices = find_devices @number
      subscribe_to @devices, @number

    if m = @devices.motions[0]
      insert_icon  "#R#{@number} #motion",  m.name, "feet"


  select = (selector) ->
    select_many(selector, 1)

  select_many = (selector, number) ->
    elements = $(selector)
    console.warn "Selector #{selector} got #{elements.length} results!" unless elements.length == number
    return elements

  select_first = (selector) ->
    select(selector)[0]

  select_room = (room, subclass) ->
    select "#R#{room} ##{subclass}"


  update_data_cell = (room, subclass, text) ->
    select_room(room, subclass).empty().append text

  relative_temperature = (v) ->
    v0 = 10
    v1 = 30
    return  (v-v0) / (v1-v0)

  limited_relative = (v) ->
    rl = relative_temperature v
    rl = 0 if rl<0
    rl = 1 if rl>1
    return rl

  temp2color = (v, a=1) ->
    rl = limited_relative v
    return "hsla(#{200*(1-rl)}, 80%, 50%, #{a})"

  set_room_attribute = (room, attributes) ->
    for key, value of attributes
      select_room(room, "box")[0].setAttribute(key, value)

  set_color = (room, color) ->
    set_room_attribute room,
      style: "fill: #{color}"
      stroke: "none"

  @set_find_devices: (f) ->
    Room.find_devices = f

  find_devices = (room) ->
    sockets:        Room.find_devices room, "socket"
    tsensor:        Room.find_devices room, "tsensor"
    tsetpoint:      Room.find_devices room, "tsetpoint"
    valves:         Room.find_devices room, "valve"
    lights:         Room.find_devices room, "light"
    lights_dimmed:  Room.find_devices room, "dimmer"
    motions:        Room.find_devices room, "motion"

  subscribe_to = (devices, room) ->
    for socket in devices.sockets
      socket.subscribe update_color("stroke", "socket"+socket.name)
    for tsensor, i in devices.tsensor
      tsensor.subscribe update_gauge(room, "RoomT", "T"+i )
      tsensor.subscribe update_summary_temperature(room) if i==0
    for tsetpoint, i in devices.tsetpoint
      tsetpoint.subscribe update_gauge(room, "RoomT", "Tset"+i )
    for valve, i in devices.valves
      valve.subscribe update_gauge(room, "RoomV", "V"+i)
    for light in devices.lights
      light.subscribe update_color("stroke", "bulb"+light.name)
    for light in devices.lights_dimmed
      id = "Dim" + light.name
      light.subscribe update_value(id)
    for motion in devices.motions
      uv = update_visibility("#"+motion.name)
      motion.subscribe uv
      uv = update_visibility("#"+motion.name)
      motion.subscribe uv


  subscribe: (subscriber) ->
    @subscribers.push subscriber

  switch_to: ->

    Room.current = @number

    # static text
    select("#Rooms .name").text @name
    select("#Rooms .number").text @number

    # temperature gauge
    if not @devices.tsensor?.length > 0
      Room.gauge.hide "RoomT"
      Room.gauge.hide_indicator "RoomT", "Needle1"
    else
      Room.gauge.show "RoomT"
      if @devices.tsensor.length == 1
        Room.gauge.hide_indicator "RoomT", "Needle1"
      else
        Room.gauge.show_indicator "RoomT", "Needle1"


    # setpoints
    if @devices.tsetpoint?.length > 0
      Room.gauge.show_indicator "RoomT", "Setpoint"
    else
      Room.gauge.hide_indicator "RoomT", "Setpoint"

    # valves
    if @devices.valves?.length > 0
      # console.log "show valve", @devices.valves[0].value, @devices.valves[0].timestamp
      Room.gauge.show "RoomV"
    else
      # console.log "hide valve"
      Room.gauge.hide "RoomV"

    # lights and sockets
    insert_icons  "#Rooms .SE", @devices.sockets,     "socket"
    insert_icons  "#Rooms .NE", @devices.lights,      "bulb"
    insert_dimmer "#Rooms .E",  @devices.lights_dimmed
    insert_icons  "#Rooms .W",  @devices.motions,     "feet"

    @refresh()

  refresh: ->
    for type, devices of @devices
      for device in devices
        device.refresh()
    for subscriber in @subscribers
      subscriber @data

  drop1st = (str) -> str.substr 1



  # also see https://codepen.io/kunukn/pen/pgqvpQ for a different, very nice design
  # (^ vertical input sliders)

  update_color = (attribute, element_name) -> (raw_value, timestamp) ->
    if typeof raw_value == 'boolean'
      value = if raw_value then 60 else 0
    else
      value = raw_value * 0.6

    if Room.current
      if element = select_first("#"+element_name)
        element.setAttribute attribute, "hsl(50, 100%, #{value}%)"

  update_visibility = (element_name) -> (visibility, timestamp) ->
    for e in select(element_name)
      e.setAttribute "visibility", (if visibility then "visible" else "hidden")

  update_text  = (element) -> (value, timestamp) ->
    $element.empty().append value.toFixed(1)

  update_value = (element_name) -> (value, timestamp) ->
    if Room.current and element_name.includes Room.current
      if element = select_first("#"+element_name)
        element.value = value

  update_gauge = (room, gauge, quantity) -> (value, timestamp) ->
    if room == Room.current
      # console.log "UG", room, gauge, quantity, value, timestamp
      data = {}
      data[gauge] = {}
      data[gauge][quantity] = {value: value, timestamp: timestamp}
      Room.gauge.setValue data

  update_summary_temperature = (room) -> (value, timestamp) ->
    update_data_cell room, "temperature", value.toFixed(1)
    update_data_cell room, "unit", "°C"
    set_color room, temp2color value


  insert_dimmer = (selector, list) ->
    # names = list.map (x) -> "Dim" + x.name
    select(selector).empty().append (sliders items: list)

  insert_icons = (selector, list, shape) ->

    cell = select(selector).empty()
    # console.log "ii", shape, list
    src = iconbar(shape: shape, items: list)
    cell.append src

  insert_icon = (selector, id, shape) ->
    cell = select(selector).empty()
    src = icon(shape: shape, id: id)
    cell.append src

  @outdoor: (data) ->
    visualize_wind(data.wind)
    visualize_temperature(data.temperature)

  @visualize_wind: (wind) ->
    dir   = wind.direction
    speed = Math.log(1 + wind.speed)

    update_flags dir, speed
    update_compass dir, speed

  @update_flags: (dir, speed) ->
    northerly = Math.cos(dir*Math.PI/180)
    westerly  = - Math.sin(dir*Math.PI/180)

    flag = select_many(".windvane", 2)
    flag[0].setAttribute("points", "0,-0.5 #{northerly * speed/3},-0.4 0 -0.3");
    flag[1].setAttribute("points", "0,-0.5 #{westerly * speed/3},-0.4 0 -0.3");


  @update_compass: (dir, speed) ->
    select_first("#windpointer").setAttribute "transform", "rotate(#{dir}) scale(#{speed * 2})"


  @visualize_temperature: (temperature) ->
    update_background_color
    color = temp2color temperature, 0.1
    select("#background").css 'background-color', color

    select("#R2201 #temperature").empty().append temperature
    select("#R2201 #unit").empty().append "°C"

    iconurl = "http://openweathermap.org/img/w/#{data.icon}.png"
    select('.weather img').attr 'src', iconurl


  @mower: (data) ->

    # console.log "mower0", data


    state = switch data["mower/status"]
      when "1" then "park"
      when "2" then "mow"
      when "3" then "return"
      when "4" then "charge"
      when "7" then "error"
      when "8" then "noloop"
      when "16" then "off"
      when "17" then "sleep"
      else "unkown"

    modes = ["auto", "manual", "home", "demo"]
    m = parseInt data["mower/mode"], 10
    mode = modes[m]

    console.log "mower", data, state, mode

    select('img.schaaf').attr 'src', "img/sheep/#{state}.jpg"
    select('img.mowermode').attr 'src', "img/sheep/#{mode}.png"

    if charge = data["mower/battery/charge"]
      select('#R888 .charge').empty().append charge
    if hours  = data["mower/statistic/hours"]
      select('#R888 .hours').empty().append hours + " h"
    if duration  = data["mower/status/duration"]
      select('#R888 .duration').empty().append duration


  @insert_gauges: ->
    insert_temperature_gauge()
    insert_valve_gauge()


  insert_temperature_gauge = ->
    Room.gauge.create
      "RoomT":
        title:    ""
        scale:    "S1":
          number:
            rotate: 0
            divisions: 4
          type:     "semi_arc"
          presets:   ["Room_Temperature", "Ticks_Left"]
          quantity:
            "T0":
              indicator:
                "Bar":      type: "bar"
                "Digital":  type: "digital"
                "Color":
                  type:       "color"
                  target:     "Bar"
                  attribute:  "stroke"
                "Needle0":
                  type:       "pointer"
                  shape:      "needle1"
            "T1":
              indicator:
                "Needle1":
                  type:       "pointer"
                  shape:      "needle1"
            "Tset0":
              indicator:
                "Setpoint":
                  type:   "pointer"
                  shape:  "right"
                  color:  "blue"
                  offset: -50
                  draggable: true

  insert_valve_gauge = ->
    Room.gauge.create
      "RoomV":
        title:    ""
        scale:    "S2":
          type:     "vertical"
          v0:     0
          v1:     100
          quantity:
            "V0":
              indicator:
                "Bar":
                  type: "bar"
                  color: "red"
                "Digital":  type: "digital"

  goto = (evt) ->
    select("#btnRooms").click();
    history.pushState {}, "Rooms", "#Rooms"
    number = drop1st evt.currentTarget.id
    room   = Room.find number
    room.switch_to()

  draw: ->

    @svg = @house.add_group "R#{@number}",
      transform: "translate(#{@x} #{4-@floor})"

    @link = @svg.add_link "R#{@number}"
    @link.node.addEventListener("click", goto)


    @link.add_rectangle "box",
      "stroke-width": 0.005
      # stroke: "none"
      x: 0.1
      y: 0.1
      width: .8
      height: .8
      rx: .2

    @svg.add_group "motion",
      transform: "scale(0.04) translate(.4 14) "

    @text = @svg.add_group "text",
      transform: "scale(0.01)"
      stroke: "none"

    @text.add_text "name", @name,
      style: "font: normal 12px serif; fill: black;"
      x: 20, y: 30

    @text.add_text "number", @number,
      style: "font: normal 8px serif; fill: black;"
      x: 20, y: 40

    @text.add_text "unit", ".",
      style: "font: normal 8px serif; fill: black;"
      x: 42, y: 80

    @text.add_text "temperature", "..",
      style: "font: normal 15px serif; fill: black;"
      x: 40, y: 60
