fs = require('fs')
Provinces = require('../lib/Provinces')

class Party
  constructor: (@id, @en, @fr, @en_abbr, @fr_abbr, @color, @onlyInProvince) ->

Contents = fs.readFileSync(__dirname + '/../data/parties.csv', 'utf-8')
Lines = Contents.split(/\r?\n/)

All = for line, i in Lines.splice(1) when line.length > 0
  [ id, en, fr, en_abbr, fr_abbr, color, onlyInProvinceCode ] = line.split(',')

  onlyInProvince = if onlyInProvinceCode
    if onlyInProvinceCode not of Provinces.byCode
      throw new Error("Invalid provinceCode #{onlyInProvinceCode} in parties.csv")
    Provinces.byCode[onlyInProvinceCode]
  else
    null

  new Party(id, en, fr, en_abbr, fr_abbr, color, onlyInProvince)

ById = {}
(ById[party.id] = party) for party in All

module.exports =
  all: All
  byId: ById
