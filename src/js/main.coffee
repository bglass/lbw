require '../css/main.css'

{Gauge} = require './gauge/gauge.coffee'
{Room}  = require './room.coffee'
{Device} = require './device.coffee'
{Weather, Sheep} = require './source.coffee'

{NodeRed} = require './node_red.coffee'
time = require './time.coffee'

{Tabs}  = require './tabs.coffee'
window.tab_select = Tabs.tab_select


rooms = {
  "001": "Entry",   "002": "Stairs",
  "008": "Toilet",    "005": "Living",
  "004": "Pantry",  "006": "Kitchen",   "007": "Laundry",
  "011": "Garage",  "012": "Party",     "101": "Lina",
  "102": "Tian",    "103": "Parents",   "104": "Bath",
  "100": "Hall",    "111": "Library",   "112": "Studio",
  "203": "Jane",      "211": "Vide",
  "212": "Cave",    "K03": "Crawl",     "K05": "Crawl",
  "202": "Office",  "2201": "Noordwijk",
  "401": "Patio",   "402": "Driveway",
  "403": "North",   "404": "Compost",
  "888": "Schaaf"
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

  Room.configure
    gauge: Gauge

  Room.create rooms

  red.subscribe "GA",       [ Device.discover, Room.setup, red.request_replay ]
  red.subscribe "dpt",      [ Device.receive ]
  red.subscribe "weather",  [ weather.receive ]
  red.subscribe "schaaf",    [ sheep.receive ]


  Device.uplink red.send
  Room.set_find_devices Device.find_type


  weather.subscribe Room.outdoor
  sheep.subscribe  Room.mower
