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
    child.$('.in-between, .share').remove()

    @listenTo(child, 'rendered', =>
      child.$('h2, .blurb').remove()
      @pymChild.sendHeight()
    )

    renderOnResize = _.throttle((=> child.render()), 500)
    $(window).on('resize.policy-score', renderOnResize)

    @$el.append(child.el)
    @pymChild.sendHeight()
