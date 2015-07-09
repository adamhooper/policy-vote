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
  votes = for i in [ 0 ... json.votesBuffer.length ] by 8
    bufferToVote(json.votesBuffer.slice(i))
  user = new User(json.id, new Date(json.createdAt), votes)

module.exports = class Database
  constructor: ->
    @userIdToIndex = {}
    @userJsons = []

  addVote: (userId, betterPolicyId, worsePolicyId) ->
    index = @userIdToIndex[userId]
    voteBuffer = buildVoteBuffer(new Date(), betterPolicyId, worsePolicyId)

    if index?
      userJson = @userJsons[index]
      userJson.votesBuffer = Buffer.concat([ userJson.votesBuffer, voteBuffer ])
    else
      index = @userIdToIndex[userId] = @userJsons.length
      userJson = @userJsons[index] = { id: userId, createdAt: new Date().toISOString(), votesBuffer: voteBuffer }

    undefined

  getUser: (userId) ->
    index = @userIdToIndex[userId]
    json = @userJsons[index]
    jsonToUser(json)

  getUsers: ->
    console.log(@userJsons)
    @userJsons.map(jsonToUser)
