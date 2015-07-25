fs = require('fs')

Contents = fs.readFileSync(__dirname + '/../data/messages.csv', 'utf-8')
Lines = Contents.split(/\r?\n/)

module.exports = (languageCode) ->
  ret = {}
  for line in Lines.splice(1) when line.length > 0
    [ key, en, fr ] = line.split(',').map((s) -> s.trim())
    ret[key] = if languageCode == 'fr' then fr else en
  ret
