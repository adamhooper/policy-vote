# Handles statistics
#
# We don't care whether the request has a cookie.

router = require('express').Router()

module.exports = (database) ->
  router.get '/n-votes-by-policy-id', (req, res) ->
    return res.status(200).send(database.getNVotesByPolicyId())

  router
