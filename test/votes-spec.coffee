supertest = require('supertest-as-promised')
Vote = require('../app/models/Vote')

describe '/votes', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(app.database)

  afterEach ->
    @sandbox.restore()

  describe 'GET /votes', ->
    it 'should return BadRequest when a cookie is not set', ->
      supertest(app)
        .get('/votes')
        .set('Accept', 'application/json')
        .expect(400).then((res) -> expect(res.body).to.have.property('code', 'cookie-not-set'))

    describe 'with a cookie set', ->
      beforeEach ->
        @agent = supertest.agent(app)
        @agent.get('/').expect(200) # set cookie

      it 'should return an empty set when there are no votes', ->
        app.database.getUser.returns(votes: [])
        @agent.get('/votes')
          .expect(200)
          .then((res) -> expect(res.body.votes).to.deep.eq([]))

      it 'should return votes when there are votes', ->
        app.database.getUser.returns(votes: [
          new Vote(new Date(), 123, 234)
          new Vote(new Date(), 235, 345)
        ])
        @agent.get('/votes')
          .expect(200)
          .then (res) ->
            votes = res.body.votes
            expect(votes.map((v) -> v.betterPolicyId)).to.deep.eq([ 123, 235 ])
            expect(votes.map((v) -> v.worsePolicyId)).to.deep.eq([ 234, 345 ])
            expect(votes[0].createdAt).to.be.at.most(votes[1].createdAt) # just testing they're set

  describe 'POST /votes', ->
    it 'should return BadRequest when a cookie is not set', ->
      supertest(app)
        .post('/votes').send(betterPolicyId: 123, worsePolicyId: 234)
        .set('Accept', 'application/json')
        .expect(400)
        .then((res) -> expect(res.body).to.have.property('code', 'cookie-not-set'))

    describe 'when a cookie is set', ->
      beforeEach ->
        @agent = supertest.agent(app)
        @agent.postJson = (json = { betterPolicyId: 123, worsePolicyId: 234 }) =>
          @agent
            .post('/votes').send(json)
            .set('Accept', 'application/json')

        @agent.testInvalidJson = (json) =>
          @agent.postJson(json)
            .expect(400)
            .then((res) -> expect(res.body).to.have.property('code', 'illegal-arguments'))

        @agent.get('/').expect(200) # set the cookie

      it 'should return NoContent', ->
        @agent.postJson().expect(201)

      it 'should return BadRequest if betterPolicyId is not set', ->
        @agent.testInvalidJson(worsePolicyId: 234)

      it 'should return BadRequest if worsePolicyId is not set', ->
        @agent.testInvalidJson(betterPolicyId: 234)

      it 'should return BadRequest if a policy ID is too large', ->
        @agent.testInvalidJson(betterPolicyId: 1, worsePolicyId: 65536)

      it 'should return BadRequest if a policy ID is zero', ->
        @agent.testInvalidJson(betterPolicyId: 0, worsePolicyId: 1)

      it 'should return BadRequest if a policy ID is negative', ->
        @agent.testInvalidJson(betterPolicyId: -1, worsePolicyId: 1)

      it 'should return BadRequest if a policy ID is not whole', ->
        @agent.testInvalidJson(betterPolicyId: 1, worsePolicyId: 1.2)

      it 'should write the vote to the database', ->
        @agent.postJson().expect(201)
          .then =>
            stub = app.database.addVote
            expect(stub).to.have.been.called
            expect(stub.args[0].slice(1)).to.deep.eq([ 123, 234 ])

      it 'should write the same user ID on each vote from the same user', ->
        @agent.postJson().expect(201)
          .then(=> @agent.postJson(betterPolicyId: 124, worsePolicyId: 235).expect(201))
          .then =>
            stub = app.database.addVote
            expect(stub).to.have.callCount(2)
            expect(stub.args[0][0]).to.eq(stub.args[1][0])
