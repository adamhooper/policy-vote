Backbone = require('backbone')

HeadingView = require('./views/HeadingView')
QuestionView = require('./views/QuestionView')
DoneView = require('./views/DoneView')
StatisticsView = require('./views/StatisticsView')
UserProfileView = require('./views/UserProfileView')

Provinces = require('../lib/Provinces')

module.exports = class App extends Backbone.View
  initialize: (options) ->
    @votes = [] # Array of [ betterPolicy, worsePolicy ]
    @userProfile = { languageCode: null, provinceCode: null } # languageCode=null means user hasn't chosen

    @userProfileView = new UserProfileView()
    @listenTo(@userProfileView, 'user-set-profile', @_onUserSetProfile)

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
    else
      @headingView?.remove()
      @questionView?.remove()
      @doneView?.remove()
      @headingView = new HeadingView()
      @questionView = new QuestionView(province: @getUserProvince())
      @doneView = new DoneView()
      @listenTo(@questionView, 'user-prefers-policy', @_onUserPrefersPolicy)
      @listenTo(@doneView, 'show-statistics', @showStatistics)
      $els = for childView in [ @headingView, @questionView, @doneView ]
        childView.render()
        childView.el
      @$el.append($els)
      @overlay = null

    @

  _onUserPrefersPolicy: (policy, otherPolicy) ->
    @votes.push([ policy, otherPolicy ])
    Backbone.ajax
      type: 'POST'
      url: '/votes'
      data: JSON.stringify(betterPolicyId: +policy.id, worsePolicyId: +otherPolicy.id)
      contentType: 'application/json'
      success: -> #console.log('Voted!')
      error: (xhr, textStatus, errorThrown) -> console.log('Error during vote', textStatus, errorThrown)
    @questionView?.render()

  _onUserSetProfile: (profile) ->
    @userProfile = profile
    @render()

  showStatistics: ->
    return if @overlay?
    view = new StatisticsView(province: @getUserProvince(), votes: @votes)
    view.render()
    @$el.append(view.el)
    @overlay = view
