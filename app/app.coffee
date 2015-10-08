process.env.NODE_ENV ||= 'development' 

express = require('express')
bodyParser = require('body-parser')
fs = require('fs')
morgan = require('morgan')
sessions = require('client-sessions')
uuid = require('node-uuid')
zlib = require('zlib')

Database = require('./Database')

app = express()
app.set('trust proxy', true)

if process.env.NODE_ENV == 'test'
  # Don't log anything
else if process.env.NODE_ENV == 'development'
  app.use(morgan('dev'))
else
  app.use(morgan('short'))

csv = if process.env.NODE_ENV == 'test'
  IgnoreWritable = require('ignore-writable')
  new IgnoreWritable(encoding: 'utf-8')
else
  fs.createWriteStream(__dirname + '/../data/votes.csv', flags: 'a', encoding: 'utf-8')

ApplicationSecret = process.env.APPLICATION_SECRET || 'not a secret'
if ApplicationSecret == 'not a secret' && process.env.NODE_ENV not in [ 'development', 'test' ]
  throw new Error('You must set an APPLICATION_SECRET environment variable')

Index =
  plain:
    en: fs.readFileSync(__dirname + '/../dist/index.html')
    fr: fs.readFileSync(__dirname + '/../dist/index.fr.html')
    standalonePolicyScore: fs.readFileSync(__dirname + '/../dist/standalone-policy-score.html')

if process.env.ASSET_BASE
  for key, buffer of Index.plain
    text = buffer.toString('utf-8')
      .replace('index.css', process.env.ASSET_BASE + '/index.css')
      .replace(/([-_a-z0-9]+)\.([a-z]{2})\.js/gi, "#{process.env.ASSET_BASE}/$1.$2.js")

    Index.plain[key] = new Buffer(text, 'utf-8')

Index.gz = {}

for lang, buffer of Index.plain
  text = buffer.toString('utf-8')

  if process.env.ASSET_BASE
    text = text
      .replace('.css"', '.css.gz"')
      .replace('.js"', '.js.gz"')

  Index.gz[lang] = zlib.gzipSync(new Buffer(text, 'utf-8'))

app.database = new Database(csvOutputStream: csv)

app.use(bodyParser.json())
app.use(sessions({
  cookieName: 'policy-vote'
  requestKey: 'policyVoteSession'
  secret: ApplicationSecret
  duration: 365 * 86400 # 1yr
}))

app.use('/votes', require('./votes')(app.database))

# Index: specially-optimized page
app.use (req, res, next) ->
  indexKey = if req.path == '/' || req.path == '/index.html'
    'en'
  else if req.path == '/index.fr.html'
    'fr'
  else if req.path == '/standalone-policy-score.html'
    'standalonePolicyScore'
  else
    null

  if indexKey?
    # Set policyVoteSession.userId when users first visit the page
    req.policyVoteSession.userId = uuid.v1()
    res.set('Content-Type', 'text/html; charset=utf-8')

    if req.acceptsEncodings('gzip')
      res.set('Content-Encoding', 'gzip')
      res.send(Index.gz[indexKey])
    else
      res.send(Index.plain[indexKey])
  else
    next()

app.get('/pym.js', (req, res) -> res.sendFile('/node_modules/pym.js/dist/pym.min.js', root: __dirname + '/..'))
app.use('/statistics', require('./statistics')(app.database))
app.use(express.static('dist'))

module.exports = app
