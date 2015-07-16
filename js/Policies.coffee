class Policy
  constructor: (@id, @en, @fr, @onlyInProvince) ->

All = require('../data/policies.csv')
  .map((obj) -> new Policy(obj.id, obj.en, obj.fr, obj.onlyInProvince || null))

module.exports = All
