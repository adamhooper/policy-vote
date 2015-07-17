streamBuffers = require('stream-buffers')
Database = require('../app/Database')
Readable = require('stream').Readable

User = require('../app/models/User')
Vote = require('../app/models/Vote')
Policies = require('../lib/Policies')

describe 'database', ->
  beforeEach ->
    @usersCsv = new streamBuffers.WritableStreamBuffer()
    @votesCsv = new streamBuffers.WritableStreamBuffer()
    @database = new Database
      usersCsvOutputStream: @usersCsv
      votesCsvOutputStream: @votesCsv
    @userId1 = 'ed84d06c-cf8f-42a3-8010-7f5e38952a34'
    @userId2 = 'ed5574c6-f060-40e9-a48d-e8c2f0ed69e6'
    @policy1 = Policies.all[0]
    @policy2 = Policies.all[1]
    @policy3 = Policies.all[2]
    @clock = sinon.useFakeTimers()

  afterEach ->
    @clock.restore()

  describe 'addUser', ->
    it 'should add the user', ->
      @clock.tick(123000)
      date = new Date() # won't change over course of test, it's mocked
      @database.addUser(@userId1, 'en', 'qc')
      expect(@database.getUsers()).to.deep.eq([
        new User(@userId1, date, 'en', 'qc', [])
      ])

    it 'should throw an exception rather than add the same User twice', ->
      fn = => @database.addUser(@userId1, 'en', 'en')
      fn()
      expect(-> fn()).to.throw("User #{@userId1} already exists")

    it 'should write the user to usersCsv', ->
      @clock.tick(new Date('2015-07-09T18:18:10.123Z').getTime())
      @database.addUser(@userId1, 'en', 'qc')
      # Assume usersCsv appends to its buffer synchronously
      expect(@usersCsv.getContentsAsString('utf8')).to.eq(
        'ed84d06c-cf8f-42a3-8010-7f5e38952a34,2015-07-09T18:18:10.123Z,en,qc\n'
      )

    it 'should write a user who has provinceCode: null', ->
      @clock.tick(new Date('2015-07-09T18:18:10.123Z').getTime())
      @database.addUser(@userId1, 'en', null)
      # Assume usersCsv appends to its buffer synchronously
      expect(@usersCsv.getContentsAsString('utf8')).to.eq(
        'ed84d06c-cf8f-42a3-8010-7f5e38952a34,2015-07-09T18:18:10.123Z,en,\n'
      )

  describe 'addVote', ->
    beforeEach ->
      @database.addUser(@userId1, 'en', null)
      @database.addUser(@userId2, 'fr', null)

    it 'should increment nVotes', ->
      expect(@database.getNVotes()).to.eq(0)
      @database.addVote(@userId1, @policy1.id, @policy2.id)
      expect(@database.getNVotes()).to.eq(1)
      @database.addVote(@userId1, @policy2.id, @policy3.id)
      expect(@database.getNVotes()).to.eq(2)

    it 'should be a no-op if userId does not point to a User', ->
      @database.addVote('8d955ef6-3f38-4aef-8075-147325c36ed5', @policy1.id, @policy2.id)
      expect(@database.getNVotes()).to.eq(0)

    it 'should be a no-op if betterPolicyId does not point to a Policy', ->
      @database.addVote(@userId1, 123456789, @policy2.id)
      expect(@database.getNVotes()).to.eq(0)

    it 'should be a no-op if worsePolicyId does not point to a Policy', ->
      @database.addVote(@userId1, @policy1.id, 123456789)
      expect(@database.getNVotes()).to.eq(0)

    it 'should write the vote to votesCsv', ->
      dateString = '2015-07-09T18:18:10.123Z'
      @clock.tick(new Date(dateString).getTime())
      @database.addVote(@userId1, @policy1.id, @policy2.id)
      expect(@votesCsv.getContentsAsString('utf8')).to.eq(
        [ @userId1, dateString, @policy1.id, @policy2.id ].join(',') + '\n'
      )

    it 'should increment nVotes for one policy and decrement for the other', ->
      o = {}
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
      @database.addVote(@userId1, @policy1.id, @policy2.id)
      o[@policy1.id] = 1
      o[@policy2.id] = -1
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
      @database.addVote(@userId1, @policy2.id, @policy3.id)
      o[@policy2.id] = 0
      o[@policy3.id] = -1
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)

  describe 'getUser', ->
    # it 'should return a User' ... is tested by #addUser() tests

    it 'should return null when the User does not exist', ->
      expect(@database.getUser(@userId1)).to.eq(null)

  describe 'load', ->
    it 'should populate Users', (done) ->
      usersCsv = new Readable()
      usersCsv._read = -> {}
      votesCsv = new Readable()
      votesCsv._read = -> {}
      @database.load usersCsv, votesCsv, (err) =>
        expect(err).not.to.exist
        expect(@database.getUsers()).to.have.length(2)
        # Test with getUser(), because that tests the mapping from ID to User
        expect(@database.getUser(@userId1)).to.deep.eq(new User(@userId1, new Date('2015-07-09T18:18:10.123Z'), 'en', 'qc'))
        expect(@database.getUser(@userId2)).to.deep.eq(new User(@userId2, new Date('2015-07-09T18:18:10.124Z'), 'fr', null))
        done()
      usersCsv.push("#{@userId1},2015-07-09T18:18:10.123Z,en,qc\n")
      usersCsv.push("#{@userId2},2015-07-09T18:18:10.124Z,fr,\n")
      usersCsv.push(null)
      votesCsv.push(null)

    it 'should populate votes', (done) ->
      usersCsv = new Readable()
      usersCsv._read = -> {}
      votesCsv = new Readable()
      votesCsv._read = -> {}
      @database.load usersCsv, votesCsv, (err) =>
        expect(err).not.to.exist
        expect(@database.getNVotes()).to.eq(3)
        o = {}
        o[@policy1.id] = 2
        o[@policy2.id] = 0
        o[@policy3.id] = -2
        expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
        done()
      usersCsv.push("#{@userId1},2015-07-09T18:18:10.123Z\n")
      usersCsv.push("#{@userId2},2015-07-09T18:18:10.124Z\n")
      usersCsv.push(null)
      votesCsv.push("#{@userId1},2015-07-09T18:18:11.000Z,#{@policy1.id},#{@policy2.id}\n")
      votesCsv.push("#{@userId2},2015-07-09T18:18:12.001Z,#{@policy1.id},#{@policy3.id}\n")
      votesCsv.push("#{@userId1},2015-07-09T18:18:13.002Z,#{@policy2.id},#{@policy3.id}\n")
      votesCsv.push(null)
