# grab any new gems
bundle
# delete and create new credentials
rm config/credentials.yml.enc
EDITOR="mate" bin/rails credentials:edit
# delete, create and seed database
rake db:drop db:create db:migrate db:seed
