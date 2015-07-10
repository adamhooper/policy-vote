Backbone = require('backbone')

HeadingView = require('./views/HeadingView')
QuestionView = require('./views/QuestionView')
DoneView = require('./views/DoneView')
StatisticsView = require('./views/StatisticsView')

module.exports = class App extends Backbone.View
  initialize: (options) ->
    throw new Error('Must pass options.policies, a Policies') if !options.policies?

    @policies = options.policies
    @votes = [] # Array of [ betterPolicy, worsePolicy ]

    @headingView = new HeadingView()
    @questionView = new QuestionView(policies: @policies)
    @doneView = new DoneView()

    @childViews = [ @headingView, @questionView, @doneView ]

    @listenTo(@questionView, 'user-prefers-policy', @_onUserPrefersPolicy)
    @listenTo(@doneView, 'show-statistics', @showStatistics)

  render: ->
    @$el.empty()
    $els = for childView in @childViews
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
      success: -> console.log('Voted!')
      error: (xhr, textStatus, errorThrown) -> console.log('Error during vote', textStatus, errorThrown)
    @questionView.render()

  showStatistics: ->
    return if @overlay?
    view = new StatisticsView(policies: @policies, votes: @votes)
    view.render()
    @$el.append(view.el)
    @overlay = view
