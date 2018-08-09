uibuilder = require('node-red-contrib-uibuilder/nodes/src/uibuilderfe.js')

exports.NodeRed = class NodeRed

  constructor: ->
    initial_set()
    uibuilder.debug false
    @debug = false
    @receivers = []
    @attach_events()


  send:  (msg) ->
    uibuilder.send msg

  sendCtrl: (msg) ->
    uibuilder.sendCtrl msg


  initial_set = ->
    $('#msgsReceived').text uibuilder.get('msgsReceived')
    $('#msgsControl').text uibuilder.get('msgsCtrl')
    $('#msgsSent').text uibuilder.get('msgsSent')
    $('#socketConnectedState').text uibuilder.get('ioConnected')
    $('#feVersion').text uibuilder.get('version')


  subscribe: (receivers) ->
    @receivers = @receivers.concat receivers



  attach_events:  ->
    # If msg changes - msg is updated when a standard msg is received from Node-RED over Socket.IO
    # Note that you can also listen for 'msgsReceived' as they are updated at the same time
    # but newVal relates to the attribute being listened to.
    uibuilder.onChange 'msg', (msg) =>
      if @debug
        console.info 'property msg changed!'
        console.dir msg
      $('#showMsg').text JSON.stringify(msg)

      for rx in @receivers
        rx msg.payload




      #uibuilder.set('msgCopy', newVal)

    # You can get attributes manually. Non-existent attributes return 'undefined'
    #console.dir(uibuilder.get('msg'))
    # You can also set things manually. See the list of attributes top of page.
    # You can add arbitrary attributes to the object, you cannot overwrite internal attributes
    # Try setting a restricted, internal attribute - see the warning in the browser console
    if @debug
      uibuilder.set 'msg', 'You tried but failed!'

    # Remember that onChange functions don't trigger if you haven't set them
    # up BEFORE an attribute change.
    uibuilder.onChange 'msgCopy', (newVal) ->
      if @debug
        console.info 'msgCopy changed. New value: ', newVal

    # Now try setting a new attribute - this will be an empty object because
    # msg won't yet have been received
    uibuilder.set 'msgCopy', uibuilder.msg

    # Hint: Try putting this set into the onChange for 'msg'
    # As noted, we could get the msg here too
    uibuilder.onChange 'msgsReceived', (newVal) ->
      if @debug
        console.info 'New msg sent to us from Node-RED over Socket.IO. Total Count: ', newVal
      $('#msgsReceived').text newVal
      # uibuilder.msg is a shortcut for uibuilder.get('msg')
      #$('#showMsg').text(JSON.stringify(uibuilder.msg))

    # If Socket.IO connects/disconnects
    uibuilder.onChange 'ioConnected', (newVal) ->
      if @debug
        console.info 'Socket.IO Connection Status Changed: ', newVal
      $('#socketConnectedState').text newVal

    # If a message is sent back to Node-RED
    uibuilder.onChange 'msgsSent', (newVal) ->
      if @debug
        console.info 'New msg sent to Node-RED over Socket.IO. Total Count: ', newVal
      $('#msgsSent').text newVal
      $('#showMsgSent').text JSON.stringify(uibuilder.get('sentMsg'))

    # If we receive a control message from Node-RED
    uibuilder.onChange 'msgsCtrl', (newVal) ->
      if @debug
        console.info 'New control msg sent to us from Node-RED over Socket.IO. Total Count: ', newVal
      $('#msgsControl').text newVal
      $('#showCtrlMsg').text JSON.stringify(uibuilder.get('ctrlMsg'))
