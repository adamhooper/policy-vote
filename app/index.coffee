fs = require('fs')

app = require('./app')

# Load the data we had before, then start listening.
#
# This is a bit, erm, race-y. We know these files exist because we just opened
# them for appending.
#
# During restart, if we're using shared files, things should look like this:
#
# 1. Old version keeps on appending to data files.
# 2. New version opens files for appending.
# 3. New version reads files.
# 4. Old version keeps appending, then dies.
# 5. New version starts appending.
#
# This should be fine:
#
# * It's fine to open a file for appending in two separate places. (Both writes
#   will append as expected -- tested on Ubuntu 15.04.)
# * Worst-case, a read from step 3 misses a write from step 4. The data isn't
#   *lost*, it just isn't *loaded*. At worst, we read a vote that has no user:
#   the app will crash, but we won't lose data. To recover, we'll need to add
#   a row to users.csv (or delete a vote from votes.csv).
#
# ... but these are worst-case scenarios. We don't expect them to ever happen.
app.database.load fs.createReadStream(__dirname + '/../data/votes.csv', 'utf-8'), (err) ->
  throw err if err?
  port = process.env['PORT'] || '3000'
  app.listen(port)
  console.log("Listening at http://localhost:#{port}")
