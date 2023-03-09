# IRIDA Next

## Requirements

* [asdf](https://asdf-vm.com)
* [asdf-node](https://github.com/asdf-vm/asdf-nodejs)
* [asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm)
* [asdf-ruby](https://github.com/asdf-vm/asdf-ruby)

## Setup

Install requirements:

```bash
asdf install
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
