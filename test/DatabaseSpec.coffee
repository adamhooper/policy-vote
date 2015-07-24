streamBuffers = require('stream-buffers')
Database = require('../app/Database')
Readable = require('stream').Readable

Policies = require('../lib/Policies')

describe 'database', ->
  beforeEach ->
    @csv = new streamBuffers.WritableStreamBuffer(encoding: 'utf-8')
    @database = new Database(csvOutputStream: @csv)
    @userId1 = 'ed84d06c-cf8f-42a3-8010-7f5e38952a34'
    @userId2 = 'ed5574c6-f060-40e9-a48d-e8c2f0ed69e6'
    @policy1 = Policies.all[0]
    @policy2 = Policies.all[1]
    @policy3 = Policies.all[2]
    @sandbox = sinon.sandbox.create(useFakeTimers: true)
    @clock = @sandbox.clock

    @vote = (userId, betterPolicyId, worsePolicyId) =>
      @database.addVote
        betterPolicyId: betterPolicyId
        worsePolicyId: worsePolicyId
        userId: userId
        timestamp: new Date()
        languageCode: 'en'
        provinceCode: 'on'
        ip: '1.2.3.4'

  afterEach ->
    @sandbox.restore()

  describe 'addVote', ->
    it 'should increment nVotes', ->
      expect(@database.getNVotes()).to.eq(0)
      @vote(@userId1, @policy1.id, @policy2.id)
      expect(@database.getNVotes()).to.eq(1)
      @vote(@userId1, @policy2.id, @policy3.id)
      expect(@database.getNVotes()).to.eq(2)

    it 'should be a no-op if betterPolicyId does not point to a Policy', ->
      @sandbox.stub(console, 'log')
      @vote(@userId1, 123456789, @policy2.id)
      expect(@database.getNVotes()).to.eq(0)

    it 'should be a no-op if worsePolicyId does not point to a Policy', ->
      @sandbox.stub(console, 'log')
      @vote(@userId1, @policy1.id, 123456789)
      expect(@database.getNVotes()).to.eq(0)

    it 'should write the vote to csv', ->
      dateString = '2015-07-09T18:18:10.123Z'
      @clock.tick(new Date(dateString).getTime())
      @vote(@userId1, @policy1.id, @policy2.id)
      expect(@csv.getContentsAsString('utf8')).to.eq(
        [ @policy1.id, @policy2.id, 'en', 'on', @userId1, '1.2.3.4' ].join(',') + '\n'
      )

    it 'should increment nVotes for one policy and decrement for the other', ->
      o = {}
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
      @vote(@userId1, @policy1.id, @policy2.id)
      o[@policy1.id] = { aye: 1, nay: 0 }
      o[@policy2.id] = { aye: 0, nay: 1 }
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
      @vote(@userId1, @policy2.id, @policy3.id)
      o[@policy2.id] = { aye: 1, nay: 1 }
      o[@policy3.id] = { aye: 0, nay: 1 }
      expect(@database.getNVotesByPolicyId()).to.deep.eq(o)

  describe 'load', ->
    it 'should populate votes', (done) ->
      csv = new Readable(encoding: 'utf-8')
      csv._read = -> {}
      @database.load csv, (err) =>
        expect(err).not.to.exist
        expect(@database.getNVotes()).to.eq(3)
        o = {}
        o[@policy1.id] = { aye: 2, nay: 0 }
        o[@policy2.id] = { aye: 1, nay: 1 }
        o[@policy3.id] = { aye: 0, nay: 2 }
        expect(@database.getNVotesByPolicyId()).to.deep.eq(o)
        done()
      csv.push("#{@policy1.id},#{@policy2.id},en,qc,#{@userId1},2015-07-09T18:18:11.000Z,1.2.3.4\n")
      csv.push("#{@policy1.id},#{@policy3.id},fr,,#{@userId2},2015-07-09T18:18:12.001Z,2.3.4.5\n")
      csv.push("#{@policy2.id},#{@policy3.id},en,qc,#{@userId1},2015-07-09T18:18:13.002Z,1.2.3.4\n")
      csv.push(null)
