streamBuffers = require('stream-buffers')
Database = require('../app/Database')
Readable = require('stream').Readable

User = require('../app/models/User')
Vote = require('../app/models/Vote')

describe 'database', ->
  beforeEach ->
    @usersCsv = new streamBuffers.WritableStreamBuffer()
    @votesCsv = new streamBuffers.WritableStreamBuffer()
    @database = new Database
      usersCsvOutputStream: @usersCsv
      votesCsvOutputStream: @votesCsv
    @userId1 = 'ed84d06c-cf8f-42a3-8010-7f5e38952a34'
    @userId2 = 'ed5574c6-f060-40e9-a48d-e8c2f0ed69e6'
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

    it 'should throw an Error if there is no User', ->
      id = '8d955ef6-3f38-4aef-8075-147325c36ed5'
      expect(=> @database.addVote(id, 123, 234)).to.throw("User #{id} does not exist")

    it 'should write the vote to votesCsv', ->
      @clock.tick(new Date('2015-07-09T18:18:10.123Z').getTime())
      @database.addVote(@userId1, 123, 234)
      expect(@votesCsv.getContentsAsString('utf8')).to.eq(
        'ed84d06c-cf8f-42a3-8010-7f5e38952a34,2015-07-09T18:18:10.123Z,123,234\n'
      )

    it 'should write one line to votesCsv for every vote, even from the same user', ->
      @clock.tick(new Date('2015-07-09T18:18:10.123Z').getTime())
      @database.addVote(@userId1, 123, 234)
      @clock.tick(1)
      @database.addVote(@userId2, 234, 123)
      @clock.tick(1) # No output should end with 125ms.
      @database.addVote(@userId1, 345, 456)
      expect(@votesCsv.getContentsAsString('utf8')).to.eq([
        'ed84d06c-cf8f-42a3-8010-7f5e38952a34,2015-07-09T18:18:10.123Z,123,234\n'
        'ed5574c6-f060-40e9-a48d-e8c2f0ed69e6,2015-07-09T18:18:10.124Z,234,123\n'
        'ed84d06c-cf8f-42a3-8010-7f5e38952a34,2015-07-09T18:18:10.125Z,345,456\n'
      ].join(''))

    it 'should add a vote', ->
      @database.addVote(@userId1, 123, 234)
      users = @database.getUsers()
      expect(users[0].votes).to.exist
      expect(users[0].votes).to.have.length(1)
      expect(users[0].votes[0]).to.have.property('betterPolicyId', 123)
      expect(users[0].votes[0]).to.have.property('worsePolicyId', 234)
      expect(users[0].votes[0].createdAt).to.be.at.most(new Date())

    it 'should add _two_ votes', ->
      @database.addVote(@userId1, 123, 234)
      @database.addVote(@userId1, 124, 235)
      users = @database.getUsers()
      expect(users[0].votes).to.have.length(2)
      expect(users[0].votes[0]).to.have.property('betterPolicyId', 123)
      expect(users[0].votes[0]).to.have.property('worsePolicyId', 234)
      expect(users[0].votes[1]).to.have.property('betterPolicyId', 124)
      expect(users[0].votes[1]).to.have.property('worsePolicyId', 235)

    it 'should separate votes by user', ->
      @database.addVote(@userId1, 123, 234)
      @database.addVote(@userId2, 234, 123)
      users = @database.getUsers()
      expect(users[0].votes).to.have.length(1)
      expect(users[0].votes[0]).to.have.property('betterPolicyId', 123)
      expect(users[0].votes[0]).to.have.property('worsePolicyId', 234)
      expect(users[1].votes).to.have.length(1)
      expect(users[1].votes[0]).to.have.property('betterPolicyId', 234)
      expect(users[1].votes[0]).to.have.property('worsePolicyId', 123)

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
        expect(@database.getUser(@userId1)).to.deep.eq(new User(@userId1, new Date('2015-07-09T18:18:10.123Z'), 'en', 'qc', []))
        expect(@database.getUser(@userId2)).to.deep.eq(new User(@userId2, new Date('2015-07-09T18:18:10.124Z'), 'fr', null, []))
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
        # Remember: the way we store dates, all milliseconds go to 0
        expect(@database.getUser(@userId1).votes).to.deep.eq([
          new Vote(new Date('2015-07-09T18:18:11.000Z'), 123, 234)
          new Vote(new Date('2015-07-09T18:18:13.000Z'), 124, 235)
        ])
        expect(@database.getUser(@userId2).votes).to.deep.eq([
          new Vote(new Date('2015-07-09T18:18:12.000Z'), 123, 235)
        ])
        done()
      usersCsv.push("#{@userId1},2015-07-09T18:18:10.123Z\n")
      usersCsv.push("#{@userId2},2015-07-09T18:18:10.124Z\n")
      usersCsv.push(null)
      votesCsv.push("#{@userId1},2015-07-09T18:18:11.000Z,123,234\n")
      votesCsv.push("#{@userId2},2015-07-09T18:18:12.001Z,123,235\n")
      votesCsv.push("#{@userId1},2015-07-09T18:18:13.002Z,124,235\n")
      votesCsv.push(null)
