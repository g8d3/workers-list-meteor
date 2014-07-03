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
  Skill.remove({})
  UserSkill.remove({})
  Problem.remove({})
  #Message.remove({})
  skill = name: 'Meteor'
  meteor = Skill.seed skill
  skill = name: 'Javascript'
  javascript = Skill.seed skill


  Problem.seed(
    {title: 'Stuck with Meteor'},
    title: 'Stuck with Meteor'
    description: 'Not yet'
    remoteViewers: [{icon: 'team viewer'}]
    skillIds: [javascript, meteor]
    userId: Meteor.users.find().fetch()[1]._id
  )
  Problem.seed(
    {title: 'Stuck with Javascript'},
    title: 'Stuck with Javascript'
    description: 'Not yet'
    remoteViewers: [{icon: 'screenhero'}]
    skillIds: [javascript]
    userId: Meteor.users.find().fetch()[0]._id
  )
  Meteor.publish null, ->
    Meteor.users.find {}, fields: {name: 1, urls: 1, site: 1, paypal: 1}

  Meteor.methods
    removeUserSkill: (userId, skillId) ->
      UserSkill.remove userId: userId, skillId: skillId
    updateUser: (attrs) ->
      Meteor.users.update {_id: Meteor.userId()}, attrs

if Meteor.isClient

  Session.set('search', null)
  Session.set('updatingProblem', null)

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

    yourSkills: ->
      Skill.find(_id: {$in: userSkills()})

    problems: ->
      Problem.find({
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
    user:-> Meteor.users.findOne(_id: @userId)

    username: -> Template.message.user.call(@).name
    userSite: -> Template.message.user.call(@).site
    userPaypal: -> Template.message.user.call(@).paypal


  Template.problem = $.extend Template.problem,
    events:
      'click .problem': (event) ->
        Session.set('chat', @title)
        Session.set('chatId', @_id)
        problem = Problem.findOne(_id: @_id, userId: Meteor.userId())
        Session.set('updatingProblem', problem)
        Session.set('updateSkillsInProblemForm', true)

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
    paypal: -> if u = Meteor.user() then u.paypal

    events:
      'keyup input': (event) ->
        if event.which == 13
          obj = {}
          value = event.target.value
          obj[event.target.name] = value
          Meteor.users.update {_id: Meteor.userId()}, $set: obj, {},
            (error) ->
              unless error then blink event.target

  Template.createProblem = $.extend Template.createProblem,
    newProblem: -> {}

  Template.updateProblem = $.extend Template.updateProblem,
    problem: -> Session.get('updatingProblem')

  Template.problemForm = $.extend Template.problemForm,
    submit: -> if @_id then 'Update' else 'Create'
    key: -> if id = @_id then 'searchSkills' + id else 'searchSkillsNew'

    skills: ->
      key = if id = @_id then 'searchSkills' + id else 'searchSkillsNew'

      if @_id and Session.get('updateSkillsInProblemForm')
        _skills = Skill.find(_id: {$in: @skillIds || []}).fetch()
        Session.set(key, _skills)
        Session.set('updateSkillsInProblemForm', false)

      Session.get(key)

    events:
      'click .skill': (event,t) ->
        key = if id = t.data._id then 'searchSkills' + id else 'searchSkillsNew'

        skill =
          _id: event.target.dataset.id
          name: event.target.innerHTML
        skills = Session.get(key) || []
        uniqSkills = _(skills.concat(skill)).uniq (skill) -> skill._id
        Session.set(key, uniqSkills)

      'click .remove': (event, t) ->
        key = if id = t.data._id then 'searchSkills' + id else 'searchSkillsNew'

        skillId = event.target.dataset.id
        skills = Session.get(key) || []
        filteredSkills = _(skills).reject (s) -> s._id == skillId
        Session.set(key,filteredSkills)

      'click .create': (event, t) ->
        key = if id = t.data._id then 'searchSkills' + id else 'searchSkillsNew'

        obj = {}
        for el in t.$('[name]')
          obj[el.name] = $(el).val()
        obj.skillIds = _(Session.get(key)).map (skill) -> skill._id
        obj.userId = Meteor.userId()

        Problem.upsert _id: t.data._id, obj, (err) ->
          unless err
            t.$('[name]').val('')
            t.$('.search').val('')
            Session.set(key, [])
            Session.set('updatingProblem', null)
            blink event.target

  Template.layout = $.extend Template.layout,
    rendered: ->
      $('body').on 'click', '.menu .icon', (event) ->
        sel = "##{event.target.title.toLowerCase()}"
        visible = $(sel).toggle().is ':visible'
        $(event.target).toggleClass('green', visible)

Router.configure
  layoutTemplate: 'layout'
Router.map ->
  @route 'skillsShow', path: '/skills'
  @route 'home', path: '/'
  @route 'test', path: '/test'
