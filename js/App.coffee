Backbone = require('backbone')

HeadingView = require('./views/HeadingView')
QuestionView = require('./views/QuestionView')
DoneView = require('./views/DoneView')

module.exports = class App extends Backbone.View
  initialize: (options) ->
    throw new Error('Must pass options.policies, a Policies') if !options.policies?

    @policies = options.policies

    @headingView = new HeadingView()
    @questionView = new QuestionView(policies: @policies)
    @doneView = new DoneView()

    @childViews = [ @headingView, @questionView, @doneView ]

    @listenTo(@questionView, 'user-prefers-policy', @_onUserPrefersPolicy)

  render: ->
    @$el.empty()
    $els = for childView in @childViews
      childView.render()
      childView.el
    @$el.append($els)

  _onUserPrefersPolicy: (policy, otherPolicy) ->
    console.log("User prefers #{policy.id} to #{otherPolicy.id}")
    Backbone.ajax
      type: 'POST'
      url: '/votes'
      data: JSON.stringify(betterPolicyId: +policy.id, worsePolicyId: +otherPolicy.id)
      contentType: 'application/json'
      success: -> console.log('Voted!')
      error: (xhr, textStatus, errorThrown) -> console.log('Error during vote', textStatus, errorThrown)
    @questionView.render()
