require '../css/main.css'

{Gauge} = require './gauge/gauge.coffee'
{House} = require './house.coffee'
{Room}  = require './room.coffee'
{Device} = require './device.coffee'
{Weather, Sheep} = require './source.coffee'

{NodeRed} = require './node_red.coffee'
time = require './time.coffee'

{Tabs}  = require './tabs.coffee'
window.tab_select = Tabs.tab_select


lbw25 = {
  "001": ["Entry",       0, 1],
  "002": ["Stairs",     -1, 3],
  "008": ["Toilet",      0, 2],
  "005": ["Living",      0, 4],
  "004": ["Pantry",     -1, 4],
  "006": ["Kitchen",     0, 5],
  "007": ["Laundry",     0, 6],
  "011": ["Garage",      0, 8],
  "012": ["Party",       0, 9],
  "101": ["Lina",        1, 1],
  "102": ["Tian",        1, 3],
  "103": ["Parents",     1, 4],
  "104": ["Bath",        1, 2],
  "100": ["Hall",        0, 3],
  "111": ["Library",     1, 8],
  "112": ["Studio",      1, 9],
  "203": ["Jane",        2, 3],
  "211": ["Vide",        2, 8],
  "212": ["Cave",        2, 9],
  "K03": ["Crawl",      -1, 1],
  "K05": ["Crawl",      -1, 2],
  "202": ["Office",      2, 2],
  "2201":["Noordwijk",   4, 0],
  "401": ["Patio",      -2, 5],
  "402": ["Driveway",   -2, 0],
  "403": ["North",       3, 0],
  "404": ["Compost",     3, 5],
  "888": ["Schaaf",    -2, 10]
}


$ ->

  # try to restore a previously selected tab in the browser
  tab = if    hash = window.location.hash.substr 1 then hash else  "House"
  $("#btn" + tab).click();

  # show the clock
  time.add
    gauge: Gauge

  red     = new NodeRed
  weather = new Weather
  sheep   = new Sheep

  House.configure
    room:  Room
    gauge: Gauge


  Room.configure
    gauge: Gauge

  Room.set_find_devices Device.find_type

  house = new House lbw25

  red.subscribe "GA",       [ Device.discover, Room.receive_group_adress_catalog, red.request_replay ]
  red.subscribe "dpt",      [ Device.receive ]
  red.subscribe "weather",  [ weather.receive ]
  red.subscribe "schaaf",    [ sheep.receive ]

  console.log "done so far"
  # Device.uplink red.send


  # weather.subscribe Room.outdoor
  # sheep.subscribe  Room.mower
