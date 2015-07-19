supertest = require('supertest-as-promised')

describe '/statistics', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(app.database)

    @agent = supertest.agent(app)

  afterEach ->
    @sandbox.restore()

  describe 'GET /statistics/n-votes-by-policy-id', ->
    it 'should return nVotesByPolicyId', ->
      nVotesByPolicyId = { 1: { aye: 2, nay: 3 }, 2: { aye: 1, nay: 1 }, 3: { aye: 2, nay: 1 } }
      app.database.getNVotesByPolicyId.returns(nVotesByPolicyId)

      @agent.get('/statistics/n-votes-by-policy-id')
        .set('Accept', 'application/json')
        .expect(200)
        .then((res) -> expect(res.body).to.deep.eq(nVotesByPolicyId))
