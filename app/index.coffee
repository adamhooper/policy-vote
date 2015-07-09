app = require('./app')

port = process.env['PORT'] || '3000'
server = app.listen(port)
