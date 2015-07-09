Database = require('../app/Database')

describe 'database', ->
  beforeEach ->
    @database = new Database()
    @userId1 = 'ed84d06c-cf8f-42a3-8010-7f5e38952a34'
    @userId2 = 'ed5574c6-f060-40e9-a48d-e8c2f0ed69e6'

  describe 'addVote', ->
    it 'should create a User entry if needed', ->
      @database.addVote(@userId1, 123, 234)
      users = @database.getUsers()
      expect(users.length).to.eq(1)
      expect(users[0].id).to.eq(@userId1)

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
