Backbone = require('backbone')
_ = require('underscore')

module.exports = class DoneView extends Backbone.View
  tagName: 'footer'
  template: _.template('''
    <button class="show-statistics">I'm done. Party time!</button>
  ''')

  events:
    'click button.show-statistics': '_onClickShowStatistics'

  render: -> @$el.html(@template())

  _onClickShowStatistics: -> @trigger('show-statistics')
