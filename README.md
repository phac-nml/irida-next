# IRIDA Next

## Requirements

- [asdf](https://asdf-vm.com)
- [asdf-node](https://github.com/asdf-vm/asdf-nodejs)
- [asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm)
- [asdf-ruby](https://github.com/asdf-vm/asdf-ruby)
  - Note: `asdf-ruby` uses [ruby-build](https://github.com/rbenv/ruby-build) and you will need to ensure you have the os level dependencies installed, which are documented [here](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment).
- [asdf-postgres](https://github.com/smashedtoatoms/asdf-postgres)
  - Note: `asdf-postgres` requires that you have the os level dependencies installed, which are documented [here](https://github.com/smashedtoatoms/asdf-postgres#dependencies)

## Setup

Install requirements:

```bash
POSTGRES_EXTRA_CONFIGURE_OPTIONS="--with-icu" asdf install
```

Verify requirements:

```bash
$ which node
/home/USERNAME/.asdf/shims/node
$ which pnpm
/home/USERNAME/.asdf/shims/pnpm
$ which ruby
/home/USERNAME/.asdf/shims/ruby
$ which postgres
/home/USERNAME/.asdf/shims/postgres
```

Ensure bundler installed:

```bash
gem install bundler
```

Install dependencies:

```bash
BUNDLE_BUILD__PG="--with-pg-config=$(asdf which pg_config)" bundle && pnpm install && bin/rails g rails_icons:sync --libraries=phosphor heroicons
```

Generate credentials:

```bash
EDITOR=nano bin/rails credentials:edit
```

Initialize the database:

```bash
bin/rails db:create db:migrate db:seed
```

## Postgres Setup

Start:

```bash
/home/USERNAME/.asdf/installs/postgres/14.17/bin/pg_ctl -D /home/USERNAME/.asdf/installs/postgres/14.17/data -l logfile start
```

Create a new role(user) and set the password

```bash
createuser -s test -P -U postgres
```

When prompted for a password for the `test` role above, set the password as `test`. These are the credentials used by the development and test databases.

Note: If using the asdf method to install and run postgres, you will need to restart the postgres server anytime the machine is rebooted.

If you would like a more permanent postgres setup on Ubuntu which the system can handle rebooting for you, you can follow these [instructions](https://linuxhint.com/install-and-setup-postgresql-database-ubuntu-22-04/), then enable and start the service using the commands below.

Enable postgresql service:

```bash
sudo systemctl enable postgresql.service
```

Start postgresql service:

```bash
sudo systemctl start postgresql.service
```

## Serve

```bash
bin/dev
```

Navigate in your browser to [http://localhost:3000](http://localhost:3000)

## Test

```bash
bin/rails test:all
```

## Running tests headful

```bash
HEADLESS=false bin/rails test:system
```

View Coverage:

Open `coverage/index.html`

## Documentation

See [docs](https://phac-nml.github.io/irida-next/).
