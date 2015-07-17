supertest = require('supertest-as-promised')
Vote = require('../app/models/Vote')

describe '/votes', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(app.database)

  afterEach ->
    @sandbox.restore()

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
