fs = require('fs')
Parties = require('./Parties')
csvrow = require('csvrow')

class Policy
  constructor: (@id, @en, @fr, @parties) ->
    @color = if @parties.length == 1 then @parties[0].color else '#898a8e'

Contents = fs.readFileSync(__dirname + '/../data/policies.csv', 'utf-8')
Lines = Contents.split(/\r?\n/)

All = for line, i in Lines.slice(1) when line.length > 0
  [ id, en, fr, partyIds ] = csvrow.parse(line).map((s) -> s.trim())
  parties = for partyId in partyIds.split(/,/)
    if partyId not of Parties.byId
      throw new Error("Invalid partyId #{partyId} near row #{i} of policies.csv")
    Parties.byId[partyId]

  new Policy(+id, en, fr, parties)

ById = {}
(ById[policy.id] = policy) for policy in All

module.exports =
  all: All
  byId: ById
