readline = require('readline')
Lazy = require('lazy')

User = require('./models/User')
Vote = require('./models/Vote')

# We encode user.votes, an Array[Vote], as a Buffer. This makes it compact
# enough to keep in memory. 1M users * 25 votes/user * 8 bytes/vote = 220MB.
VoteBufferSize = 8

buildVoteBuffer = (createdAt, betterPolicyId, worsePolicyId) ->
  ret = new Buffer(VoteBufferSize)
  ret.writeUInt32BE(Math.floor(createdAt / 1000), 0, true)
  ret.writeUInt16BE(betterPolicyId, 4, true)
  ret.writeUInt16BE(worsePolicyId, 6, true)
  ret

bufferToVote = (buf) ->
  createdAt = new Date(buf.readUInt32BE(0) * 1000)
  betterPolicyId = buf.readUInt16BE(4)
  worsePolicyId = buf.readUInt16BE(6)
  new Vote(createdAt, betterPolicyId, worsePolicyId)

jsonToUser = (json) ->
  votes = if json.votesBuffer.length > 0
    for i in [ 0 ... json.votesBuffer.length ] by 8
      bufferToVote(json.votesBuffer.slice(i))
  else
    []
  user = new User(json.id, new Date(json.createdAt), json.languageCode, json.provinceCode, votes)

userJsonToCsvBuffer = (userJson) ->
  new Buffer([
    userJson.id
    userJson.createdAt
    userJson.languageCode
    userJson.provinceCode || ''
  ].join(',') + '\n', 'utf8')

voteToCsvBuffer = (userId, timestamp, betterPolicyId, worsePolicyId) ->
  new Buffer([ userId, timestamp.toISOString(), betterPolicyId, worsePolicyId ].join(',') + '\n', 'utf8')

# Holds all the values that end-users will set: Users and Votes.
#
# The database is entirely in-memory. We anticipate:
#
# * Absolute max: 1M users
# * Upper-bound expected number of votes, on average: 25 votes per user
# * Storage space: 8 bytes per vote -- that is, 200 bytes per user
# * total: 200MB, plus maybe 100 bytes of overhead per user -> 300MB.
#
# We also persist values, for two reasons:
#
# 1. Statistical analysis -- hence a CSV output format
# 2. Persistent state -- i.e., reloading the app
#
# It's no big deal if we lose a vote or two.
#
# The database is write-only, which means we only ever *append* to our CSV
# files, `users.csv` and `votes.csv`. We keep things super-simple by ignoring
# the write() return value: a hard failure will kill the app, but a full buffer
# will simply force Node to use up more memory (which is fine). As a result,
# most methods return synchronously.
module.exports = class Database
  # Options:
  #
  # * usersCsvOutputStream: where to write when a new User is created.
  # * votesCsvOutputSTream: where to write when a new Vote is created.
  constructor: (options={}) ->
    throw 'Must set options.usersCsvOutputStream' if !options.usersCsvOutputStream?.write
    throw 'Must set options.votesCsvOutputStream' if !options.votesCsvOutputStream?.write

    @userIdToIndex = {}
    @userJsons = []

    @usersCsvOutputStream = options.usersCsvOutputStream
    @votesCsvOutputStream = options.votesCsvOutputStream

  _getUserJson = (userId) ->
    index = @userIdToIndex[userId]
    if index? # 0 is a valid index
      @userJsons[index]
    else
      null

  # Adds a Vote to the database for the given User.
  addVote: (userId, betterPolicyId, worsePolicyId) ->
    timestamp = new Date()
    userJson = @_getUserJson(userId) ? throw new Error("User #{userId} does not exist")
    voteBuffer = buildVoteBuffer(timestamp, betterPolicyId, worsePolicyId)
    userJson.votesBuffer = Buffer.concat([ userJson.votesBuffer, voteBuffer ])

    @votesCsvOutputStream.write(voteToCsvBuffer(userId, timestamp, betterPolicyId, worsePolicyId))

    undefined

  # Returns the User with the given ID.
  #
  # If the user does not exist, that means the database was wiped but the
  # client's cookie persisted. Return null.
  getUser: (userId) ->
    userJson = @_getUserJson(userId)
    userJson && jsonToUser(userJson) || null

  # Adds userJson to @userIdToIndex and @userJsons.
  #
  # Does not write to output CSV.
  _addUserJson: (userJson) ->
    @userIdToIndex[userJson.id] = @userJsons.length
    @userJsons.push(userJson)

  _getUserJson: (userId) ->
    index = @userIdToIndex[userId]
    if index?
      @userJsons[index]
    else
      null

  # Modifies a User in the database.
  addUser: (userId, languageCode, provinceCode) ->
    throw new Error("User #{userId} already exists") if @userIdToIndex[userId]?
    userJson =
      id: userId
      createdAt: new Date().toISOString()
      votesBuffer: new Buffer(0)
      languageCode: languageCode
      provinceCode: provinceCode
    @_addUserJson(userJson)
    @usersCsvOutputStream.write(userJsonToCsvBuffer(userJson))
    undefined

  # Gets all User objects.
  #
  # Useful for testing. Not so much on production.
  getUsers: ->
    @userJsons.map(jsonToUser)

  # Populates the database from previously-written CSV files.
  #
  # This method is asynchronous. You probably mean to run it on app startup; in
  # that case, don't respond to users until the loading is finished.
  load: (usersCsv, votesCsv, done) ->
    throw new Error('The database is not empty. DO NOT call load() now.') if @userJsons.length
    @_loadUsersCsv usersCsv, =>
      @_loadVotesCsv(votesCsv, done)

  _loadUsersCsv: (usersCsv, done) ->
    index = 0
    new Lazy(usersCsv)
      .lines
      .forEach (line) =>
        [ userId, createdAt, languageCode, provinceCode ] = line.toString('utf8').split(',')
        userJson =
          id: userId
          createdAt: createdAt
          votesBuffer: new Buffer(0)
          languageCode: languageCode
          provinceCode: provinceCode || null
        @_addUserJson(userJson)
    usersCsv.on('end', done)

  _loadVotesCsv: (votesCsv, done) ->
    new Lazy(votesCsv)
      .lines
      .forEach (line) =>
        [ userId, createdAt, betterPolicyId, worsePolicyId ] = line.toString('utf8').split(',')
        voteBuffer = buildVoteBuffer(new Date(createdAt), +betterPolicyId, +worsePolicyId)
        userJson = @userJsons[@userIdToIndex[userId]]
        userJson.votesBuffer = Buffer.concat([ userJson.votesBuffer, voteBuffer ])
    votesCsv.on('end', done)
