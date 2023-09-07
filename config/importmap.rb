# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://ga.jspm.io/npm:flowbite@1.6.5/lib/esm/index.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.7/dist/esm/index.js'
pin 'flowbite-datepicker', to: 'https://ga.jspm.io/npm:flowbite-datepicker@1.2.2/js/main.js'
pin '@sindresorhus/slugify', to: 'https://ga.jspm.io/npm:@sindresorhus/slugify@2.2.0/index.js'
pin '@sindresorhus/transliterate', to: 'https://ga.jspm.io/npm:@sindresorhus/transliterate@1.6.0/index.js'
pin 'escape-string-regexp', to: 'https://ga.jspm.io/npm:escape-string-regexp@5.0.0/index.js'
pin 'lodash', to: 'https://ga.jspm.io/npm:lodash@4.17.21/lodash.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
