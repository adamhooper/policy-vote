express = require('express')

app = express()

app.use(express.static('dist'))

server = app.listen(3000)
