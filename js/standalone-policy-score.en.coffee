Backbone = require('backbone')
pym = require('pym.js')
$ = Backbone.$

global.Messages = require('./Messages')('en')
(o.name = o.en) for o in require('../lib/Parties').all
(o.abbr = o.en_abbr) for o in require('../lib/Parties').all
(o.name = o.en) for o in require('../lib/Provinces').all
(o.name = o.en) for o in require('../lib/Policies').all

$ ->
  pymChild = new pym.Child()

  $main = $('<div id="main"></div>').appendTo('body')
  StandalonePolicyScoreApp = require('./StandalonePolicyScoreApp')
  app = new StandalonePolicyScoreApp(el: $main, pymChild: pymChild)
  app.render()
