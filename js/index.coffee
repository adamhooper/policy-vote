$ = require('jquery');

App = require('./App');

$ ->
  $main = $('<div id="main"></div>').appendTo('body')

  app = new App
    el: $main
  app.render()
