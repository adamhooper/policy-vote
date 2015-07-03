$ = require('jquery');

App = require('./App');
Policies = require('./collections/Policies')

$ ->
  $main = $('<div id="main"></div>').appendTo('body')

  policies = new Policies(require('../data/policies.csv'))

  app = new App
    el: $main
    policies: policies
  app.render()
