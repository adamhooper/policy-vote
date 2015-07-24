# Handles votes.
#
# Each vote request must come with a cookie.
router = require('express').Router()

PolicyIds = require('../lib/Policies').byId # id => ???
LanguageCodes = require('../lib/Languages').byCode # id => ???
ProvinceCodes = require('../lib/Provinces').byCode # id => ???

module.exports = (database) ->
  router.post '/', (req, res) ->
    userId = req.policyVoteSession.userId

    return res.status(400).send(code: 'cookie-not-set') if !userId

    betterPolicyId = req.body?.betterPolicyId
    worsePolicyId = req.body?.worsePolicyId
    languageCode = req.body?.languageCode
    provinceCode = req.body?.provinceCode

    if betterPolicyId not of PolicyIds || worsePolicyId not of PolicyIds || languageCode not of LanguageCodes || (provinceCode != null && provinceCode not of ProvinceCodes)
      return res.status(400).send(code: 'illegal-arguments')

    database.addVote
      betterPolicyId: betterPolicyId
      worsePolicyId: worsePolicyId
      languageCode: languageCode
      provinceCode: provinceCode ? ''
      userId: userId
      ip: req.ip

    res.sendStatus(201)

  router
