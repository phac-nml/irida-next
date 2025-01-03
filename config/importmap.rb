# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@2.5.2/dist/flowbite.turbo.min.js'
pin '@popperjs/core', to: '@popperjs--core.js' # @2.11.7
pin '@sindresorhus/slugify', to: '@sindresorhus--slugify.js' # @2.2.1
pin '@sindresorhus/transliterate', to: '@sindresorhus--transliterate.js' # @1.6.0
pin 'escape-string-regexp' # @5.0.0
pin '@rails/activestorage', to: '@rails--activestorage.js' # @7.2.201
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'xlsx' # @0.18.5
pin 'validator' # @13.12.0
pin_all_from 'app/javascript/utilities', under: 'utilities'
pin 'sortablejs' # @1.15.2
pin 'local-time' # @3.0.2
pin 'lodash' # @4.17.21
