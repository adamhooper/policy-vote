# Handles votes.
#
# Each vote request must come with a cookie.
router = require('express').Router()

# Returns true iff the policy ID is permitted.
#
# We don't do a database check here -- i.e., no foreign key checks. But we do
# check that PolicyId is an integer greater than 0 and less than 65536.
isValidPolicyId = (id) ->
  typeof(id) == 'number' && 0 < id <= 65535 && Math.floor(id) == id

module.exports = (database) ->
  router.post '/', (req, res) ->
    userId = req.policyVoteSession.userId
    betterPolicyId = req.body?.betterPolicyId
    worsePolicyId = req.body?.worsePolicyId

    return res.status(400).send(code: 'cookie-not-set') if !userId

    if !isValidPolicyId(betterPolicyId) || !isValidPolicyId(worsePolicyId)
      return res.status(400).send(code: 'illegal-arguments')

    database.addVote(userId, betterPolicyId, worsePolicyId)

    res.status(201).send("")

  router
