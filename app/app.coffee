express = require('express')
bodyParser = require('body-parser')
fs = require('fs')
sessions = require('client-sessions')
uuid = require('node-uuid')

Database = require('./Database')

app = express()

app.database = new Database()

app.use(bodyParser.json())
app.use(sessions({
  cookieName: 'policy-vote'
  requestKey: 'policyVoteSession'
  secret: fs.readFileSync('config/client-session-secret.txt', 'utf-8')
  duration: 365 * 86400 # 1yr
}))

# Set policyVoteSession.userId when users first visit the page
app.use (req, res, next) ->
  if req.path == '/'
    req.policyVoteSession.userId ||= uuid.v1()
  next()

app.use('/votes', require('./vote')(app.database))
app.use(express.static('dist'))

module.exports = app
