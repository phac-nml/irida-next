# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version
  3.2.0

- System dependencies

- Configuration

- Database creation

- Database initialization

- How to run the test suite

  1. Run pnpm install

    - `pnpm install`

  2. Compile Assets

    - `bin/bundle exec rails assets:precompile`

  3. Run Tests

    - `bin/rails test`

  4. Viewing Coverage

  - Open `coverage/index.html`

- Services (job queues, cache servers, search engines, etc.)

- Deployment instructions

- Run rails server:
  - Install UI dependencies: `pnpm install`
  - `foreman start -f Procfile.dev`
