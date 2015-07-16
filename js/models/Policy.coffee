Backbone = require('backbone')

module.exports = class Policy extends Backbone.Model
  defaults:
    en: ''
    fr: ''
    parties: []

  parse: (json) ->
    id: json.id
    en: json.en
    fr: json.fr
    parties: json.parties.split(/,/)
