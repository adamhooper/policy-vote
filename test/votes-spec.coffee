supertest = require('supertest-as-promised')

Policies = require('../lib/Policies')

describe '/votes', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(app.database)
    @policy1 = Policies.all[0]
    @policy2 = Policies.all[2]

  afterEach ->
    @sandbox.restore()

  describe 'POST /votes', ->
    it 'should return BadRequest when a cookie is not set', ->
      supertest(app)
        .post('/votes').send(betterPolicyId: @policy1.id, worsePolicyId: @policy2.id)
        .set('Accept', 'application/json')
        .expect(400)
        .then((res) -> expect(res.body).to.have.property('code', 'cookie-not-set'))

    describe 'when a cookie is set', ->
      beforeEach ->
        @agent = supertest.agent(app)
        @agent.postJson = (json={}) =>
          json =
            betterPolicyId: json.betterPolicyId ? @policy1.id
            worsePolicyId: json.worsePolicyId ? @policy2.id
            languageCode: json.languageCode ? 'en'
            provinceCode: json.provinceCode ? 'on'
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

      it 'should return BadRequest if betterPolicyId is empty', ->
        @agent.testInvalidJson(betterPolicyId: '')

      it 'should return BadRequest if worsePolicyId is empty', ->
        @agent.testInvalidJson(worsePolicyId: '')

      it 'should return BadRequest if betterPolicyId is invalid', ->
        @agent.testInvalidJson(betterPolicyId: 65535)

      it 'should return BadRequest if worsePolicyId is invalid', ->
        @agent.testInvalidJson(worsePolicyId: 65535)

      it 'should return BadRequest if languageCode is invalid', ->
        @agent.testInvalidJson(languageCode: 'eng')

      it 'should return BadRequest if provinceCode is invalid', ->
        @agent.testInvalidJson(provinceCode: 'ont')

      it 'should return BadRequest if languageCode is empty', ->
        @agent.testInvalidJson(languageCode: '')

      it 'should NOT return BadRequest if provinceCode is empty', ->
        @agent.postJson(provinceCode: '').expect(201)

      it 'should write the vote to the database', ->
        @agent.postJson().expect(201)
          .then (res) =>
            stub = app.database.addVote
            expect(stub).to.have.been.called
            expect(stub.args[0][0]).to.include
              betterPolicyId: @policy1.id
              worsePolicyId: @policy2.id
              languageCode: 'en'
              provinceCode: 'on'

            # I can't find how to get an IP out of superagent. Let's assume
            # the IP is either '127.0.0.1' or '::ffff:127.0.0.1'....
            expect(stub.args[0][0].ip).to.match(/127.0.0.1$/)

      it 'should write the same user ID on each vote from the same user', ->
        @agent.postJson().expect(201)
          .then(=> @agent.postJson().expect(201))
          .then =>
            stub = app.database.addVote
            expect(stub).to.have.callCount(2)
            expect(stub.args[0][0].userId).to.eq(stub.args[1][0].userId)
