Setting up a deployment server
==============================

See `provision-ec2.sh`. First it describes some variables on EC2 and how they
were created (through the Web interface). Make sure the variables are correct
and check on AWS that everything is wired appropriately, then run
`./provision-ec2.sh`.

It may fail. This isn't exactly highly-used code; it may be buggy.

Deploying
---------

First deploy: run `setup-deploy.sh`, and on the server, create a file
`/opt/policy-vote/APPLICATION_SECRET` owned by `pm2:pm2` with a long secret
string.

Subsequent deploys: run `deploy.sh`
