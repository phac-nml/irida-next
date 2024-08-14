# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.1'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.3'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.4'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use devise for auth
gem 'devise', '~> 4.9.4'

# Use OmniAuth auth
gem 'omniauth'
gem 'omniauth-azure-activedirectory-v2'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'

# API Integrations
gem 'faraday'
gem 'faraday-multipart'
gem 'faraday-net_http_persistent', '~> 2.0'

# Use Sass to process CSS
# gem "sassc-rails"

# Tailwind CSS [https://tailwindcss.com]
gem 'tailwindcss-rails', '~> 2.6'
gem 'view_component', '~> 3.12'

# Pagy
gem 'pagy', '~> 6.1' # omit patch digit

# Ransack
gem 'ransack', '~> 4.1', '>= 4.1.1'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem 'graphiql-rails'
gem 'graphql'

# rubocop
gem 'rubocop', require: false
gem 'rubocop-graphql', require: false
gem 'rubocop-rails', require: false

# postgresql
gem 'pg'

# Authorization
gem 'action_policy'
gem 'action_policy-graphql'

# Auditing
gem 'logidze'

# Database functions
gem 'fx'
# Soft delete records
gem 'paranoia'

# Validate json schema's
gem 'activerecord_json_validator', '~> 3.0.0'

# ActiveStorage
gem 'active_storage_validations'
gem 'aws-sdk-s3', require: false
gem 'azure-storage-blob', github: 'honeyankit/azure-storage-ruby', branch: 'master', require: false
gem 'google-cloud-storage', '~> 1.11', require: false

# job queueing
gem 'good_job', '~> 3.99'

# spreadsheet parser [https://github.com/roo-rb/roo]
gem 'roo', '~> 2.10.0'
gem 'roo-xls'

# create zip file for data exports
gem 'zip_kit'

# set expiry date for data exports
gem 'business_time'
gem 'holidays'

# csv
gem 'csv'

# write xlsx
gem 'caxlsx'

# renders client's local time zone
gem 'local_time', '~> 3.0', '>= 3.0.2'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  gem 'faker'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # erb-formatter
  gem 'erb-formatter', '~> 0.7.2', require: false

  # LookBook
  gem 'actioncable'
  gem 'listen'
  gem 'lookbook', '~> 2.1', '>= 2.1.1'

  # Solargraph
  gem 'solargraph'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'capybara-lockstep'
  gem 'cuprite'

  gem 'simplecov', require: false
  gem 'timecop'

  gem 'webmock'
end

gem 'activerecord-session_store', '~> 2.1'
