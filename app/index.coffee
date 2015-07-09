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
#   the app will crash and come right back online after a second.
#
# ... but these are worst-case scenarios. Normally, all will be well.
app.database.load fs.createReadStream('./data/users.csv'), fs.createReadStream('./data/votes.csv'), (err) ->
  throw err if err?
  port = process.env['PORT'] || '3000'
  app.listen(port)
  console.log("Listening at http://localhost:#{port}")
