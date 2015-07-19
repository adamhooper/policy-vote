readline = require('readline')
Lazy = require('lazy')

User = require('./models/User')
PolicyIds = require('../lib/Policies').byId

userToCsvBuffer = (user) ->
  new Buffer([
    user.id
    user.createdAt.toISOString()
    user.languageCode
    user.provinceCode || ''
  ].join(',') + '\n', 'utf8')

voteToCsvBuffer = (userId, timestamp, betterPolicyId, worsePolicyId) ->
  new Buffer([ userId, timestamp.toISOString(), betterPolicyId, worsePolicyId ].join(',') + '\n', 'utf8')

# Holds all the values that end-users will set: Users and Votes.
#
# The database is write-only, which means we only ever *append* to our CSV
# files, `users.csv` and `votes.csv`. We keep things super-simple by ignoring
# the write() return value: a hard failure will kill the app, but a full buffer
# will simply force Node to use up more memory (which is fine, as long as
# traffic subsides). So most methods return synchronously.
#
# We keep the Users in memory forever: when a user votes, we need that lookup
# to find language/province to write to votes.csv.
#
# But we don't keep Votes in memory: there's no need. Our statistics don't need
# such analysis.
#
# We anticipate:
#
# * Absolute max: 5M users. ~50b/user (assuming JavaScript is
#   memory-inefficient) -> 250MB in memory
# * Upper-bound expected number of votes: average 20 votes per user (100M votes
#   total) at ~100b/vote -> 10GB in votes.csv
#
# It's no big deal if we lose a vote or two. (That's why we return before a
# disk write succeeds.)
module.exports = class Database
  # Options:
  #
  # * usersCsvOutputStream: where to write when a new User is created.
  # * votesCsvOutputSTream: where to write when a new Vote is created.
  constructor: (options={}) ->
    throw 'Must set options.usersCsvOutputStream' if !options.usersCsvOutputStream?.write
    throw 'Must set options.votesCsvOutputStream' if !options.votesCsvOutputStream?.write

    @_nUsers = 0
    @_nVotes = 0
    @_nVotesByPolicyId = {}
    @_users = {}

    @usersCsvOutputStream = options.usersCsvOutputStream
    @votesCsvOutputStream = options.votesCsvOutputStream

  # Adds the vote, but doesn't write to CSV.
  #
  # Returns true if the vote is new
  _addVote: (userId, betterPolicyId, worsePolicyId) ->
    # Don't write invalid policy IDs: that would let one user ruin the
    # experience for everybody.
    #
    # Don't allow invalid userIds. This is more questionable, since we assume
    # the request came from a valid user, or otherwise where did the request's
    # (unspoofable) userId come from? But whatever -- arbitrary decision.
    if userId of @_users && betterPolicyId of PolicyIds && worsePolicyId of PolicyIds
      @_nVotes++
      @_nVotesByPolicyId[betterPolicyId] ?= { aye: 0, nay: 0 }
      @_nVotesByPolicyId[betterPolicyId].aye++
      @_nVotesByPolicyId[worsePolicyId] ?= { aye: 0, nay: 0 }
      @_nVotesByPolicyId[worsePolicyId].nay++
      true
    else
      false

  # Adds a Vote to the database for the given User.
  addVote: (userId, betterPolicyId, worsePolicyId) ->
    if @_addVote(userId, betterPolicyId, worsePolicyId)
      @votesCsvOutputStream.write(voteToCsvBuffer(userId, new Date(), betterPolicyId, worsePolicyId))
    else
      console.log('skipped', userId, betterPolicyId, worsePolicyId)

  # Returns the total number of votes.
  getNVotes: -> @_nVotes

  # Returns the User with the given ID.
  #
  # If the user does not exist, that means the database was wiped but the
  # client's cookie persisted. Return null.
  getUser: (userId) -> @_users[userId] ? null

  # Adds a User to the database.
  addUser: (userId, languageCode, provinceCode) ->
    throw new Error("User #{userId} already exists") if @_users[userId]?
    @_nUsers++
    user = @_users[userId] = new User(userId, new Date(), languageCode, provinceCode)
    @usersCsvOutputStream.write(userToCsvBuffer(user))
    undefined

  # Gets all User objects.
  #
  # Useful for testing. DO NOT USE in production, as it does not scale.
  getUsers: -> user for __, user of @_users

  # Returns an Object mapping policy ID (stringified) to a Number of votes.
  #
  # The Number returned is the number of *aye* votes minus the number of *nay*
  # votes.
  getNVotesByPolicyId: -> @_nVotesByPolicyId

  # Populates the database from previously-written CSV files.
  #
  # This method is asynchronous. You probably mean to run it on app startup; in
  # that case, don't respond to users until the loading is finished.
  load: (usersCsv, votesCsv, done) ->
    throw new Error('The database is not empty. DO NOT call load() now.') if @_nUsers > 0
    @_loadUsersCsv usersCsv, (err) =>
      return done(err) if err?
      @_loadVotesCsv(votesCsv, done)

  _loadUsersCsv: (usersCsv, done) ->
    index = 0
    new Lazy(usersCsv)
      .lines
      .forEach (line) =>
        [ userId, createdAt, languageCode, provinceCode ] = line.toString('utf8').split(',')
        @_nUsers++
        @_users[userId] = new User(userId, new Date(createdAt), languageCode, provinceCode || null)
    usersCsv.on('end', done)

  _loadVotesCsv: (votesCsv, done) ->
    new Lazy(votesCsv)
      .lines
      .forEach (line) =>
        [ userId, __, betterPolicyId, worsePolicyId ] = line.toString('utf-8').split(',')
        @_addVote(userId, betterPolicyId, worsePolicyId)
    votesCsv.on('end', done)
