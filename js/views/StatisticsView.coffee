Backbone = require('backbone')

ForAgainstView = require('./ForAgainstView')

module.exports = class StatisticsView extends Backbone.View
  className: 'statistics'

  initialize: (options) ->
    throw 'must pass options.policies, a Policies' if !options.policies
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @policies = options.policies
    @votes = options.votes

  render: ->
    forAgainstView = new ForAgainstView(policies: @policies, votes: @votes)
    forAgainstView.render()
    @$el.append(forAgainstView.el)
    @
