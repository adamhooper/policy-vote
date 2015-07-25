Backbone = require('backbone')
pym = require('pym.js');
$ = Backbone.$

Provinces = require('../lib/Provinces')

module.exports = class App extends Backbone.View
  initialize: (options) ->
    throw 'Must call App.setLanguage() first with "en" or "fr"' if !global.languageCode

    @votes = [] # Array of [ betterPolicy, worsePolicy ]
    @userSetProfile = false
    @userProfile = { provinceCode: null }

    @pymChild = new pym.Child()

    UserProfileView = require('./views/UserProfileView')
    @userProfileView = new UserProfileView()
    @listenTo(@userProfileView, 'user-set-profile', @_onUserSetProfile)
    @listenTo(@userProfileView, 'user-clicked', => @pymChild.sendHeight())
    @showStatistics = false

  getUserProvince: ->
    if @userProfile.provinceCode?
      Provinces.byCode[@userProfile.provinceCode]
    else
      null

  render: ->
    @$el.empty()

    if !@userSetProfile
      @userProfileView.render()
      @$el.append(@userProfileView.el)
    else if !@showStatistics
      if !@questionView?
        QuestionView = require('./views/QuestionView')
        @questionView = new QuestionView(province: @getUserProvince())
        @listenTo(@questionView, 'user-prefers-policy', @_onUserPrefersPolicy)
        @listenTo(@questionView, 'show-statistics', @_onClickShowStatistics)
        @questionView.render()
      else
        @questionView.delegateEvents()
      @$el.append(@questionView.el)
    else
      @statisticsView?.remove()

      StatisticsView = require('./views/StatisticsView')
      @statisticsView = new StatisticsView(province: @getUserProvince(), votes: @votes)
      @listenTo(@statisticsView, 'rendered', => @pymChild.sendHeight())
      @listenTo(@statisticsView, 'clicked-back-to-questions', @_onClickBackToQuestions)
      @$el.append(@statisticsView.render().el)
      @statisticsView.tidyRenderGlitches()

    @pymChild.sendHeight()

    @

  _onUserPrefersPolicy: (policy, otherPolicy) ->
    @votes.push([ policy, otherPolicy ])
    Backbone.ajax
      type: 'POST'
      url: '/votes'
      data: JSON.stringify
        betterPolicyId: +policy.id
        worsePolicyId: +otherPolicy.id
        languageCode: global.languageCode
        provinceCode: @userProfile.provinceCode
      contentType: 'application/json'
      success: -> #console.log('Voted!')
      error: (xhr, textStatus, errorThrown) -> console.log("Server didn't register your vote", textStatus, errorThrown)
    @questionView.render()
    @pymChild.sendHeight()

  _onUserSetProfile: (profile) ->
    @userSetProfile = true
    @userProfile = profile
    @render()

  _onClickShowStatistics: ->
    @showStatistics = true
    @render()

  _onClickBackToQuestions: ->
    @showStatistics = false
    @statisticsView.remove()
    @statisticsView = null
    @render()

App.setLanguage = (languageCode) ->
  global.languageCode = languageCode
  # Set global.Messages before require()-ing any Views. That lets use use a
  # global variable ... yay!
  global.Messages = require('./Messages')(languageCode)
  (o.name = o[languageCode]) for o in require('../lib/Parties').all
  (o.name = o[languageCode]) for o in require('../lib/Provinces').all
  (o.name = o[languageCode]) for o in require('../lib/Policies').all

App.installOnPageLoad = ->
  $ ->
    $main = $('<div id="main"></div>').appendTo('body')
    app = new App(el: $main)
    app.render()
