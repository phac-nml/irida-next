# IRIDA Next

## Requirements

- [asdf](https://asdf-vm.com)
- [asdf-node](https://github.com/asdf-vm/asdf-nodejs)
- [asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm)
- [asdf-ruby](https://github.com/asdf-vm/asdf-ruby)
  - Note: `asdf-ruby` uses [ruby-build](https://github.com/rbenv/ruby-build) and you will need to ensure you have the os level dependencies installed, which are documented [here](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment).
- [asdf-postgres](https://github.com/smashedtoatoms/asdf-postgres)
  - Note: `asdf-postgres` requires the following os level dependencies `linux-headers-$(uname -r) build-essential libssl-dev libreadline-dev zlib1g-dev libcurl4-openssl-dev uuid-dev icu-devtools`. These can be installed using `sudo apt-get install`

## Setup

Install requirements:

```bash
asdf install
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
bundle && pnpm install
```

Initialize the database:

```bash
bin/rails db:create db:migrate
```

## Postgres Setup

Start:

```bash
/home/USERNAME/.asdf/installs/postgres/14.6/bin/pg_ctl -D /home/USERNAME/.asdf/installs/postgres/14.6/data -l logfile start
```

Create a new role(user) and set the password

```bash
createuser -s test -P -U postgres
```

When prompted for a password for the `test` role above, set the password as `test`. These are the credentials used by the development and test databases.

Note: If using the asdf method to install and run postgres, you will need to restart the postgres server anytime the machine is rebooted.

If you would like a more permanent postgres setup on Ubuntu which the system can handle rebooting for you, you can follow these [instructions](https://linuxhint.com/install-and-setup-postgresql-database-ubuntu-22-04/). After setting up postgresql you will need enable the postgresql systemctl service `sudo systemctl enable postgresql.service` and start the server `sudo systemctl start postgresql.service`

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

See [docs](/docs/README.md).
