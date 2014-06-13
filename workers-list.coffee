Meteor.Collection::seed = (findAttrs, insertAttrs = findAttrs) ->
  @insert(insertAttrs) unless @findOne(findAttrs)

Meteor.Collection::match = (selector, options) ->
  for key, value of selector
    selector[key] = {$regex: new RegExp(value,'i')}
  @find(selector, options)

@Skill     = new Meteor.Collection('skills')
@UserSkill = new Meteor.Collection('userSkills')

UserSkill.allow
  insert: (userId, doc) ->
    doc.userId == userId and not UserSkill.findOne(skillId: doc.skillId)

Meteor.users.allow
  update: (userId, user) ->
    user._id == userId

if Meteor.isServer
  Skill.remove({})
  UserSkill.remove({})
  Meteor.users.update(
    {_id: 'ufpuadt3SYF6qdaMk'},
    {$set: {name: 'asd', urls: [{href: 'qwe',content: 'content'}]}})
  Skill.seed name: 'Meteor'
  Skill.seed name: 'Javascript'

  Meteor.publish null, ->
    Meteor.users.find {}, fields: {name: 1, urls: 1}

  Meteor.methods
    removeUserSkill: (userId, skillId) ->
      UserSkill.remove userId: userId, skillId: skillId
    updateUser: (attrs) ->
      Meteor.users.update {_id: Meteor.userId()}, attrs

if Meteor.isClient
  Session.set('search', null)
  Session.set('s', null)

  blink = (element) ->
    $(element).nextAll('.hidden.notice:first').fadeIn(200, -> $(@).fadeOut(1300))

  Template.skills = $.extend Template.skills,
    skills: ->
      if Session.get('search')
        Skill.match name: ".*#{Session.get('search')}.*"

    events:
      'keyup .search': (event) ->
        Session.set('search', event.target.value)
      'keyup .create': (event) ->
        if event.which == 13
          name = event.target.value
          event.target.value = ''
          Skill.insert name: name , (error, id) ->
            unless error
              blink event.target
      'keyup .edit': (event) ->
        if event.which == 13
          _id = event.target.dataset.id
          name = event.target.value
          Skill.update {_id: _id}, name: name, {}, (error) ->
            unless error
              blink event.target
      'click .remove': (event) ->
        Skill.remove event.target.dataset.id

  Template.usersSkills = $.extend Template.usersSkills,
    users: -> Meteor.users.find()

  Template.userSkills = $.extend Template.userSkills,
    skills: ->
      if Session.get('s' + @_id)
        Skill.match name: ".*#{Session.get('s' + @_id)}.*"

    yourSkills: ->
      userSkills = UserSkill.find(userId: Meteor.userId()).fetch()
      skillIds = (userSkill.skillId for userSkill in userSkills)
      Skill.find(_id: {$in: skillIds})

    events:
      'keyup .search': (event,t) ->
        Session.set('s' + @_id, event.target.value)
      'click .skill': (event) ->
        skillId = event.target.dataset.id
        UserSkill.insert
          userId: Meteor.userId(), skillId: skillId, (error) ->
            unless error then blink event.target
      'click .remove': (event) ->
        skillId = event.target.dataset.id
        Meteor.call('removeUserSkill', Meteor.userId(), skillId)

Router.configure
  layoutTemplate: 'layout'
Router.map ->
  @route 'skillsShow', path: '/skills'
  @route 'home', path: '/'
