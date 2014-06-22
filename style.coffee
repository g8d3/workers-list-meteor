if Meteor.isClient
  Template.chat = $.extend Template.chat,
    rendered: ->
      $('.messages').css
        height: $(document).height() * 0.65
