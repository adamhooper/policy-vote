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

module.exports = class Database
  constructor: ->
    @userIdToIndex = {}
    @userJsons = []

  _insertOrGetUser: (userId) ->
    index = @userIdToIndex[userId]
    if index? # 0 is a valid index
      @userJsons[index]
    else
      index = @userIdToIndex[userId] = @userJsons.length
      @userJsons[index] = { id: userId, createdAt: new Date().toISOString(), votesBuffer: new Buffer(0) }

  addVote: (userId, betterPolicyId, worsePolicyId) ->
    voteBuffer = buildVoteBuffer(new Date(), betterPolicyId, worsePolicyId)
    userJson = @_insertOrGetUser(userId)
    userJson.votesBuffer = Buffer.concat([ userJson.votesBuffer, voteBuffer ])

    undefined

  getUser: (userId) ->
    userJson = @_insertOrGetUser(userId)
    jsonToUser(userJson)

  getUsers: ->
    @userJsons.map(jsonToUser)
