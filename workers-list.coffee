Meteor.Collection::seed = (findAttrs, insertAttrs = findAttrs) ->
  @insert(insertAttrs) unless @findOne(findAttrs)

@Skill = new Meteor.Collection('skills')

if Meteor.isServer
  #Skill.remove({})
  Skill.seed name: 'Meteor'

if Meteor.isClient
  Template.test.skills = -> Skill.find().fetch()

  Template.test.rendered = ->
    angular.module('app', []).
    controller('skillC',['$scope', (s) ->
      s.skills = ->
      return
    ])


