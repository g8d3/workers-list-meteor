Meteor.Collection::seed = (findAttrs, insertAttrs = findAttrs) ->
  @insert(insertAttrs) unless @findOne(findAttrs)

Meteor.Collection::match = (selector, options) ->
  for key, value of selector
    selector[key] = {$regex: new RegExp(value,'i')}
  @find(selector, options)

@Skill     = new Meteor.Collection('skills')
@UserSkill = new Meteor.Collection('userSkills')
@Problem   = new Meteor.Collection('problems')
@Message   = new Meteor.Collection('messages')

UserSkill.allow
  insert: (userId, doc) ->
    doc.userId == userId and not UserSkill.findOne(userId: userId, skillId: doc.skillId)

Meteor.users.allow
  update: (userId, user) ->
    user._id == userId

if Meteor.isServer
  Houston.add_collection(Meteor.users)
  #Skill.remove({})
  #UserSkill.remove({})
  #Problem.remove({})
  meteor = Skill.seed name: 'Meteor'
  javascript = Skill.seed name: 'Javascript'

  Problem.seed
    title: 'Stuck with Meteor'
    description: 'Not yet'
    remoteViewers: [{icon: 'team viewer'}]
    skillIds: [javascript, meteor]
  Problem.seed
    title: 'Stuck with Javascript'
    description: 'Not yet'
    remoteViewers: [{icon: 'screenhero'}]
    skillIds: [javascript]

  Meteor.publish null, ->
    Meteor.users.find {}, fields: {name: 1, urls: 1, site: 1}

  Meteor.methods
    removeUserSkill: (userId, skillId) ->
      UserSkill.remove userId: userId, skillId: skillId
    updateUser: (attrs) ->
      Meteor.users.update {_id: Meteor.userId()}, attrs

if Meteor.isClient

  Session.set('search', null)

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

  userSkills = ->
    _userSkills = UserSkill.find(userId: Meteor.userId()).fetch()
    (userSkill.skillId for userSkill in _userSkills)

  Template.skillsSearch = $.extend Template.skillsSearch,
    rendered: ->
      Session.set('s' + @data, null)
      Session.set('searchFocused' + @data, null)

    searchFocused: -> Session.get('searchFocused' + @)

    events:
      'keyup .search': (event,t) ->
        Session.set('s' + @, event.target.value)
      'focus .search': (event) -> Session.set('searchFocused' + @, true)
      'click .hide-results': (event) -> Session.set('searchFocused' + @, false)

    skills: ->
      # @_id makes session key to change for each template instance
      if Session.get('s' + @)
        Skill.match name: ".*#{Session.get('s' + @)}.*"

  Template.searchProblems = $.extend Template.searchProblems,
    skillsSearchId: -> Session.set('ssi',)

    yourSkills: ->
      Skill.find(_id: {$in: userSkills()})

    problems: -> Problem.find({
      skillIds: {$in: userSkills()}
    },
      sort: {createdAt: -1}
    )

    events:
      'click .skill': (event) ->
        skillId = event.target.dataset.id
        UserSkill.insert
          userId: Meteor.userId(), skillId: skillId, (error) ->
            unless error then blink event.target
      'click .remove': (event) ->
        skillId = event.target.dataset.id
        Meteor.call('removeUserSkill', Meteor.userId(), skillId)

  Template.message = $.extend Template.message,
    user:->
      Meteor.users.findOne(_id: @userId)

    username: ->
      Template.message.user.call(@).name

    userSite: ->
      Template.message.user.call(@).site


  Template.problem = $.extend Template.problem,
    events:
      'click .problem': (event) ->
        Session.set('chat', @title)
        Session.set('chatId', @_id)

  Template.problemSkillName = $.extend Template.problemSkillName,
    name: ->
      Skill.findOne(_id: '' + @).name

  Template.chat = $.extend Template.chat,
    chat: -> Session.get('chat')

    messages: ->
      Message.find
        problemId: Session.get('chatId')

    events:
      'keyup .new-message': (event) ->
        if event.which == 13
          Message.insert
            userId: Meteor.userId()
            text: event.target.value
            problemId: Session.get('chatId'), (error) ->
              unless error then event.target.value = ''

  Template.profile = $.extend Template.profile,
    username: -> if u = Meteor.user() then u.name
    site: -> if u = Meteor.user() then u.site

    events:
      'keyup input': (event) ->
        if event.which == 13
          obj = {}
          value = event.target.value
          obj[event.target.name] = value
          Meteor.users.update {_id: Meteor.userId()}, $set: obj, {},
            (error) ->
              unless error then blink event.target

  Template.home = $.extend Template.home,
    rendered: ->
      $('.dropdown').dropdown()

Router.configure
  layoutTemplate: 'layout'
Router.map ->
  @route 'skillsShow', path: '/skills'
  @route 'home', path: '/'
  @route 'profile', path: '/profile'
