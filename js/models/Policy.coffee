Backbone = require('backbone')

module.exports = class Policy extends Backbone.Model
  defaults:
    category: ''
    party: ''
    policy: ''
