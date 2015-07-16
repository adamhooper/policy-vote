Backbone = require('backbone')

ForAgainstView = require('./ForAgainstView')

module.exports = class StatisticsView extends Backbone.View
  className: 'statistics'

  initialize: (options) ->
    throw 'must pass options.province, the user\'s Province' if 'province' not of options
    throw 'must pass options.votes, an Array[[Policy,Policy]] of better/worse policies' if !options.votes

    @province = options.province
    @votes = options.votes

  render: ->
    forAgainstView = new ForAgainstView(province: @province, votes: @votes)
    forAgainstView.render()
    @$el.append(forAgainstView.el)
    @
