exports.Tabs = {}

exports.Tabs.tab_select = (evt, selected) ->

  $(".tablinks").removeClass('active')
  $(evt.currentTarget).addClass('active')
  $(".tabcontent").hide()
  $("#"+selected).show()
