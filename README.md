# IRIDA Next

## Requirements

* [asdf](https://asdf-vm.com)
* [asdf-node](https://github.com/asdf-vm/asdf-nodejs)
* [asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm)
* [asdf-ruby](https://github.com/asdf-vm/asdf-ruby)
  * Note: `asdf-ruby` uses [ruby-build](https://github.com/rbenv/ruby-build) and you will need to ensure you have the os level dependencies installed, which are documented [here](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment).

## Setup

Install requirements:

```bash
asdf install
```

Verify requirements:

```bash
$ which nodejs
/home/USERNAME/.asdf/shims/node
$ which pnpm
/home/USERNAME/.asdf/shims/node
$ which ruby
/home/USERNAME/.asdf/shims/ruby
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

## Serve

```bash
bin/dev
```

Navigate in your browser to [http://localhost:3000](http://localhost:3000)

## Test

```bash
bin/rails test:prepare test
```

View Coverage:

Open `coverage/index.html`

## Documentation

See [docs](/docs/README.md).
