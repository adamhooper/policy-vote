# Handles a user's profile.
#
# Each request must come with a cookie.

router = require('express').Router()

ValidLanguageCodes = require('./languages').byCode
ValidProvinceCodes = require('./provinces').byCode

module.exports = (database) ->
  router.post '/', (req, res) ->
    userId = req.policyVoteSession.userId
    languageCode = req.body?.languageCode
    provinceCode = req.body?.provinceCode

    return res.status(400).send(code: 'cookie-not-set') if !userId

    if languageCode not of ValidLanguageCodes || provinceCode not of ValidProvinceCodes
      return res.status(400).send(code: 'illegal-arguments')

    if !database.getUser(userId)
      database.addUser(userId, languageCode, provinceCode)

    res.status(201).send()

  router
