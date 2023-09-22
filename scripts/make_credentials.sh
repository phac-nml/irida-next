# delete and create new credentials
rm config/credentials.yml.enc
EDITOR="mate" bin/rails credentials:edit
