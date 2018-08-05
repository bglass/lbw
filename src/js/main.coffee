require '../css/index.css'

{NodeRed} = require './node_red.coffee'
time = require './time.coffee'

{Tabs}  = require './tabs.coffee'
window.tab_select = Tabs.tab_select





$ ->

  $("#btnDebug").click();

  time.add()

  red = new NodeRed

  #Manually send a message back to Node-RED after 2 seconds
  window.setTimeout (->
    console.info 'Sending a message back to Node-RED - after 2s delay'
    console.info "Yo!"
    red.send
      'topic': 'uibuilderfe'
      'payload': 'I am a message sent from the uibuilder front end'
  ), 2000

  # Manually send a control message. Include cacheControl:REPLAY to test cache handling
  # Shouldn't be needed in this example since window.load will also send cacheControl and we should
  # be done before then.
  red.sendCtrl 'cacheControl': 'REPLAY'
