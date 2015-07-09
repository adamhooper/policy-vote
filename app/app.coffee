process.env.NODE_ENV ||= 'dev'

express = require('express')
bodyParser = require('body-parser')
fs = require('fs')
morgan = require('morgan')
sessions = require('client-sessions')
uuid = require('node-uuid')

Database = require('./Database')

app = express()

if process.env.NODE_ENV == 'test'
  # Don't log anything
else if process.env.NODE_ENV == 'dev'
  app.use(morgan('dev'))
else
  app.use(morgan('short'))

databaseOptions = if process.env.NODE_ENV == 'test'
  IgnoreWritable = require('ignore-writable')
  usersCsvOutputStream: new IgnoreWritable
  votesCsvOutputStream: new IgnoreWritable
else
  usersCsvOutputStream: process.stdout
  votesCsvOutputStream: process.stdout

app.database = new Database(databaseOptions)

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
