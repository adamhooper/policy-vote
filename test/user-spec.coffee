supertest = require('supertest-as-promised')
User = require('../app/models/User')

describe '/user', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(app.database)

  afterEach ->
    @sandbox.restore()

  describe 'POST /user', ->
    beforeEach ->
      app.database.addUser.returns(undefined)
      app.database.getUser.returns(null)

      @agent = supertest.agent(app)
      @agent.postJson = (json={ languageCode: 'en', provinceCode: 'qc' }) =>
        @agent
          .post('/user').send(json)
          .set('Accept', 'application/json')

      @agent.testInvalidJson = (json) =>
        @agent.postJson(json)
          .expect(400)
          .then((res) -> expect(res.body).to.have.property('code', 'illegal-arguments'))

    it 'should return BadRequest when a cookie is not set', ->
      @agent.postJson()
        .expect(400)
        .then((res) -> expect(res.body).to.have.property('code', 'cookie-not-set'))

    describe 'with a cookie set', ->
      beforeEach ->
        @agent.get('/').expect(200) # set cookie

      it 'should return BadRequest when languageCode is not set', ->
        @agent.testInvalidJson(provinceCode: 'qc')

      it 'should call database.postUser() when languageCode and provinceCode are valid', ->
        @agent.postJson(languageCode: 'en', provinceCode: 'qc')
          .expect(201)
          .then (res) ->
            stub = app.database.addUser
            expect(stub).to.have.been.called
            expect(stub.args[0].slice(1)).to.deep.eq([ 'en', 'qc' ])

      it 'should call database.postUser() when provinceCode is not set', ->
        @agent.postJson(languageCode: 'en', provinceCode: null)
          .expect(201)
          .then (res) ->
            stub = app.database.addUser
            expect(stub).to.have.been.called
            expect(stub.args[0].slice(1)).to.deep.eq([ 'en', null ])

      it 'should not accept a languageCode other than `en` or `fr`', ->
        @agent.testInvalidJson(languageCode: 'sp', provinceCode: 'qc')

      it 'should not accept an invalid provinceCode', ->
        @agent.testInvalidJson(languageCode: 'en', provinceCode: 'qb')

      it 'should be a no-op if the User is already in the database', ->
        app.database.getUser.returns(new User()) # meh, I won't bother with fake params
        @agent.postJson(languageCode: 'en', provinceCode: 'qc')
          .expect(201)
          .then (res) ->
            expect(app.database.addUser).not.to.have.been.called

