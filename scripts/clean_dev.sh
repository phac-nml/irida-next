# clean storage
rm -r storage/*
# grab any new gems
bundle
# delete, create and seed database
bin/rails db:drop db:create db:migrate db:seed
