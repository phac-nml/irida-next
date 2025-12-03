# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Enable integrity calculation for all pins
enable_integrity!

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.7/dist/esm/index.js'
pin '@sindresorhus/slugify', to: '@sindresorhus--slugify.js' # @2.2.1
pin '@sindresorhus/transliterate', to: '@sindresorhus--transliterate.js' # @1.6.0
pin 'escape-string-regexp' # @5.0.0
pin '@rails/activestorage', to: '@rails--activestorage.js' # @7.2.201
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'xlsx' # @0.18.5
pin_all_from 'app/javascript/utilities', under: 'utilities'
pin 'sortablejs' # @1.15.2
pin 'local-time' # @3.0.2
pin 'lodash' # @4.17.21
pin 'focus-trap' # @7.6.5
pin 'tabbable' # @6.2.0
pin 'uuid' # @13.0.0
