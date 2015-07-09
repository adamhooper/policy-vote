# Stores all our data that is editable by users or editors.
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
  user = new User(json.id, new Date(json.createdAt), votes)

userJsonToCsvBuffer = (userJson) ->
  new Buffer([ userJson.id, userJson.createdAt ].join(',') + '\n', 'utf8')

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

  _insertOrGetUser: (userId) ->
    index = @userIdToIndex[userId]
    if index? # 0 is a valid index
      @userJsons[index]
    else
      userJson = { id: userId, createdAt: new Date().toISOString(), votesBuffer: new Buffer(0) }
      @userIdToIndex[userId] = @userJsons.length
      @userJsons.push(userJson)
      @usersCsvOutputStream.write(userJsonToCsvBuffer(userJson))
      userJson

  addVote: (userId, betterPolicyId, worsePolicyId) ->
    timestamp = new Date()
    voteBuffer = buildVoteBuffer(timestamp, betterPolicyId, worsePolicyId)
    userJson = @_insertOrGetUser(userId)
    userJson.votesBuffer = Buffer.concat([ userJson.votesBuffer, voteBuffer ])

    @votesCsvOutputStream.write(voteToCsvBuffer(userId, timestamp, betterPolicyId, worsePolicyId))

    undefined

  getUser: (userId) ->
    userJson = @_insertOrGetUser(userId)
    jsonToUser(userJson)

  getUsers: ->
    @userJsons.map(jsonToUser)
