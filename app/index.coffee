fs = require('fs')

app = require('./app')

# Load the data we had before, then start listening.
#
# This is a bit, erm, race-y. We know these files exist because we just opened
# them for appending.
#
# During restart, if we're using shared files, things should look like this:
#
# 1. Old version keeps on appending to data file.
# 2. New version opens file for appending.
# 3. New version reads file.
# 4. Old version keeps appending, then dies.
# 5. New version starts appendin.
#
# This should be fine:
#
# * It's fine to open a file for appending twice simultaneously. (Both writes
#   will append as expected -- tested on Ubuntu 15.04.)
# * Worst-case, a read from step 3 misses a write from step 4. The data isn't
#   *lost*, it just isn't *loaded*. The vote is missing until next restart.
#
# ... we don't expect that to ever happen.
app.database.load fs.createReadStream(__dirname + '/../data/votes.csv', encoding: 'utf-8'), (err) ->
  throw err if err?
  port = process.env['PORT'] || '3000'
  app.listen(port)
  console.log("Listening at http://localhost:#{port}")
