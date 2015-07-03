express = require('express')

app = express()

app.use(express.static('dist'))

port = process.env['PORT'] || '3000'

server = app.listen(port)
