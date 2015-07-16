Parties = require('./Parties')

class Policy
  constructor: (@id, @en, @fr, @parties) ->

All = require('../data/policies.csv')
  .map (obj, i) ->
    parties = for partyId in obj.partyIds.split(',')
      if partyId not of Parties.byId
        throw new Error("Invalid partyId #{partyId} near row #{i} of policies.csv")
      Parties.byId[partyId]

    new Policy(
      obj.id,
      obj.en,
      obj.fr,
      parties
    )

ById = {}
(ById[policy.id] = policy) for policy in All

module.exports =
  all: All
  byId: ById
