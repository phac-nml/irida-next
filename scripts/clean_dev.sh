# clean storage
rm -rf storage/*
rm -rf tmp/storage/*
# grab any new gems
bundle
# delete, create and migrate databases
# includes primary: and jobs: databases
bin/rails info db:drop db:create db:migrate
# seed db, attachment max set to 50 for quick seed time
SEED_MAXIMUM_TOTAL_SAMPLE_ATTACHMENTS=50 bin/rails info db:seed
