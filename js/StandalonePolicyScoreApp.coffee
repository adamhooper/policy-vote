_ = require('underscore')
Backbone = require('backbone')
StatisticsView = require('./views/StatisticsView')
$ = Backbone.$

module.exports = class StandalonePolicyScoreApp extends Backbone.View
  initialize: (options) ->
    throw new Error('Must pass options.pymChild, a pym.Child') if !options.pymChild
    @pymChild = options.pymChild

  render: ->
    child = new StatisticsView(province: 'qc', votes: []) # 'qc' shows all parties; others don't
    child.render()

    cleanThings = -> child.$('.in-between, .share, h2, .blurb').remove()
    cleanThings()

    @listenTo(child, 'rendered', =>
      cleanThings()
      @pymChild.sendHeight()
    )

    @$el.append(child.el)
    @pymChild.sendHeight()
