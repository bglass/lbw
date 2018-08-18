require '../css/main.css'

{House} = require './house.coffee'
{Room}  = require './room.coffee'
{Device} = require './device.coffee'

{NodeRed} = require './node_red.coffee'
time = require './time.coffee'

{Tabs}  = require './tabs.coffee'
window.tab_select = Tabs.tab_select


rooms = {
  "001": "Entry",   "008": "Toilet",    "005": "Living",
  "004": "Pantry",  "006": "Kitchen",   "007": "Laundry",
  "011": "Garage",  "012": "Party",     "101": "Lina",
  "102": "Tian",    "103": "Parents",   "104": "Bath",
  "100": "Hall",    "111": "Library",   "112": "Studio",
  "202": "Top",     "203": "Jane",      "211": "Vide",
  "212": "Cave",    "K03": "Crawl",     "K05": "Crawl",
  "201": "Office"
}




$ ->

  tab = if    hash = window.location.hash.substr 1 then hash else  "House"
  $("#btn" + tab).click();

  time.add()

  house = new House
  house.setup
    rooms:  rooms
    target: Room.goto

  Room.create rooms

  red = new NodeRed

  red.subscribe_ga [ Device.discover, Room.setup, red.request_replay ]
  red.subscribe    [ Device.receive, house.receive ]



  # #Manually send a message back to Node-RED after 2 seconds
  # window.setTimeout (->
  #   console.info 'Sending a message back to Node-RED - after 2s delay'
  #   console.info "Yo!"
  #   red.send
  #     'topic': 'uibuilderfe'
  #     'payload': 'I am a message sent from the uibuilder front end'
  # ), 2000

  # Manually send a control message. Include cacheControl:REPLAY to test cache handling
  # Shouldn't be needed in this example since window.load will also send cacheControl and we should
  # be done before then.
  # red.sendCtrl 'cacheControl': 'REPLAY'
