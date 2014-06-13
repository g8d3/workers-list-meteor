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

if Meteor.isServer
  Skill.remove({})
  UserSkill.remove({})
  Skill.seed name: 'Meteor'
  Skill.seed name: 'Javascript'
  Meteor.methods
    removeUserSkill: (userId, skillId) ->
      UserSkill.remove userId: userId, skillId: skillId
    updateUser: (attrs) ->
      Meteor.users.update {_id: Meteor.userId()}, attrs

if Meteor.isClient
  Session.set('search', null)
  Session.set('s', null)
  Session.set('created', false)

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
        _id = event.target.dataset.id
        Skill.remove _id: _id

  Template.userSkills = $.extend Template.userSkills,
    skills: ->
      if Session.get('s')
        Skill.match name: ".*#{Session.get('s')}.*"

    yourSkills: ->
      userSkills = UserSkill.find(userId: Meteor.userId()).fetch()
      skillIds = (userSkill.skillId for userSkill in userSkills)
      Skill.find(_id: {$in: skillIds})

    user: -> Meteor.user()

    email: -> Meteor.user().emails[0].address

    added: -> Session.get('added')

    events:
      'keyup .search': (event) ->
        Session.set('s', event.target.value)
      'click .skill': (event) ->
        skillId = event.target.dataset.id
        UserSkill.insert
          userId: Meteor.userId(), skillId: skillId, (error) ->
            unless error then blink event.target
      'click .remove': (event) ->
        skillId = event.target.dataset.id
        Meteor.call('removeUserSkill', Meteor.userId(), skillId)
