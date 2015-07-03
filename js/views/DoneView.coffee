Backbone = require('backbone')
_ = require('underscore')

module.exports = class DoneView extends Backbone.View
  tagName: 'footer'
  template: _.template('''
    <p>[TODO: add button here for when user is done choosing]</p>
  ''')

  render: -> @$el.html(@template())
