process.env.NODE_ENV ||= 'development' 

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
else if process.env.NODE_ENV == 'development'
  app.use(morgan('dev'))
else
  app.use(morgan('short'))

databaseOptions = if process.env.NODE_ENV == 'test'
  IgnoreWritable = require('ignore-writable')
  usersCsvOutputStream: new IgnoreWritable
  votesCsvOutputStream: new IgnoreWritable
else
  usersCsvOutputStream: fs.createWriteStream('./data/users.csv', flags: 'a')
  votesCsvOutputStream: fs.createWriteStream('./data/votes.csv', flags: 'a')

ApplicationSecret = process.env.APPLICATION_SECRET || 'not a secret'
if ApplicationSecret == 'not a secret' && process.env.NODE_ENV not in [ 'development', 'test' ]
  throw new Error('You must set an APPLICATION_SECRET environment variable')

app.database = new Database(databaseOptions)

app.use(bodyParser.json())
app.use(sessions({
  cookieName: 'policy-vote'
  requestKey: 'policyVoteSession'
  secret: ApplicationSecret
  duration: 365 * 86400 # 1yr
}))

# Set policyVoteSession.userId when users first visit the page
app.use (req, res, next) ->
  if req.path == '/'
    req.policyVoteSession.userId ||= uuid.v1()
  next()

app.use(express.static('data')) # FIXME remove this! Just for showing stuff to clients
app.use('/votes', require('./vote')(app.database))
app.use(express.static('dist'))

module.exports = app
