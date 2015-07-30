fs = require('fs')
csvrow = require('csvrow')

Contents = fs.readFileSync(__dirname + '/../data/messages.csv', 'utf-8')
Lines = Contents.split(/\r?\n/)

formatNumber = (n, languageCode) -> n

# Returns a Messages object. Looks like this:
#
#   {
#     "StatisticsView": {
#       "promisedBy": "promisedBy"
#     }
#   }
module.exports = (languageCode) ->
  ret = {}
  for line in Lines.splice(1) when line.length > 0
    [ key, en, fr ] = csvrow.parse(line).map((s) -> s.trim())
    splitKey = key.split('.')
    o = ret
    while splitKey.length > 1
      o = (o[splitKey.shift()] ||= {})
    o[splitKey[0]] = if languageCode == 'fr' then fr else en

  ret.n = (n) ->
    if n < 10
      ret.Numeral[String(n)]
    else
      n

  ret
