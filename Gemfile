# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.4', '>= 7.0.4.2'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

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
gem 'devise', '~> 4.9.2'

# Use OmniAuth auth
gem 'omniauth'
gem 'omniauth-azure-activedirectory-v2'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'

# Use Figaro to set and organize environment variables
gem 'figaro'

# Use Sass to process CSS
# gem "sassc-rails"

# Tailwind CSS [https://tailwindcss.com]
gem 'tailwindcss-rails', '~> 2.0'
gem 'view_component'

# Pagy
gem 'pagy', '~> 6.0' # omit patch digit

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

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

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'lookbook', '>= 2.0.0.rc.1'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  gem 'graphiql-rails'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # erb-formatter
  gem 'erb-formatter', git: 'https://github.com/nebulab/erb-formatter.git', tag: 'v0.4.2', require: false

  # LookBook
  gem 'actioncable'
  gem 'listen'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'cuprite'

  gem 'simplecov', require: false
end
