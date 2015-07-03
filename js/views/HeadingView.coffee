Backbone = require('backbone')
_ = require('underscore')

module.exports = class HeadingView extends Backbone.View
  tagName: 'header'
  template: _.template('''
    <h1>Pick the idea you prefer:</h1>
  ''')

  render: -> @$el.html(@template())
