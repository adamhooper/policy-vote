Provinces = require('../app/provinces')

class Party
  constructor: (@id, @en, @fr, @onlyInProvince) ->

All = require('../data/parties.csv')
  .map (obj) ->
    onlyInProvince = if obj.onlyInProvinceCode
      if obj.onlyInProvinceCode not of Provinces.byCode
        throw new Error("Invalid provinceCode #{obj.onlyInProvinceCode} in parties.csv")
      Provinces.byCode[obj.onlyInProvinceCode]
    else
      null

    new Party(
      obj.id,
      obj.en,
      obj.fr,
      onlyInProvince
    )

ById = {}
(ById[party.id] = party) for party in All

module.exports =
  all: All
  byId: ById
