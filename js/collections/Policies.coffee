Backbone = require('backbone')

Policy = require('../models/Policy')

module.exports = class Policies extends Backbone.Collection
  model: Policy
