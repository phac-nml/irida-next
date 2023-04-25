FROM ruby:3.2.0-slim as base

WORKDIR /rails

ENV RAILS_ENV=production \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
# This example intentionally does not require or install node.js

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN gem update --system && gem install bundler

# Install application gems
COPY Gemfile Gemfile.lock ./

# TODO: consolidate bundle config better, currently split between ENV and `bundle config`
RUN bundle config frozen true \
    && bundle config jobs 4 \
    && bundle config deployment true \
    && bundle config without 'development test' \
    && bundle install \
    && bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Install node and pnpm
RUN curl -sL https://deb.nodesource.com/setup_19.x  | bash - \
    && apt-get install -yq --no-install-recommends nodejs \
    && npm install -g pnpm@7.29.1 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Install node_modules
RUN pnpm install --frozen-lockfile

# Precompile assets
# SECRET_KEY_BASE or RAILS_MASTER_KEY is required in production, but we don't
# want real secrets in the image or image history. The real secret is passed in
# at run time
ARG SECRET_KEY_BASE=fakekeyforassets
RUN ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --home /rails --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

ARG DATABASE_URL
ARG SECRET_KEY_BASE

# Start Server
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
