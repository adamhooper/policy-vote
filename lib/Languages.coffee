class Language
  constructor: (@code, @name) ->

all = [
  new Language('en', 'English')
  new Language('fr', 'Français')
]

byCode = {}
(byCode[language.code] = language) for language in all

module.exports =
  all: all
  byCode: byCode
