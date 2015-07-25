Backbone = require('backbone')
pym = require('pym.js');
$ = Backbone.$

UserProfileView = require('./views/UserProfileView')
QuestionView = require('./views/QuestionView')
StatisticsView = require('./views/StatisticsView')

Provinces = require('../lib/Provinces')

module.exports = class App extends Backbone.View
  initialize: (options) ->
    @votes = [] # Array of [ betterPolicy, worsePolicy ]
    @userProfile = { languageCode: null, provinceCode: null } # languageCode=null means user hasn't chosen

    @pymChild = new pym.Child()

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

    if !@userProfile.languageCode?
      @userProfileView.render()
      @$el.append(@userProfileView.el)
    else if !@showStatistics
      if !@questionView?
        @questionView = new QuestionView(province: @getUserProvince())
        @listenTo(@questionView, 'user-prefers-policy', @_onUserPrefersPolicy)
        @listenTo(@questionView, 'show-statistics', @_onClickShowStatistics)
      @$el.append(@questionView.render().el)
    else
      if !@statisticsView?
        @statisticsView = new StatisticsView(province: @getUserProvince(), votes: @votes)
        @listenTo(@statisticsView, 'rendered', => @pymChild.sendHeight())
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
        languageCode: @userProfile.languageCode
        provinceCode: @userProfile.provinceCode
      contentType: 'application/json'
      success: -> #console.log('Voted!')
      error: (xhr, textStatus, errorThrown) -> console.log("Server didn't register your vote", textStatus, errorThrown)
    @questionView.render()
    @pymChild.sendHeight()

  _onUserSetProfile: (profile) ->
    @userProfile = profile
    @render()

  _onClickShowStatistics: ->
    @showStatistics = true
    @render()

App.installOnPageLoad = ->
  $ ->
    $main = $('<div id="main"></div>').appendTo('body')
    app = new App(el: $main)
    app.render()
