# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'flowbite', to: 'https://cdnjs.cloudflare.com/ajax/libs/flowbite/1.6.3/flowbite.turbo.min.js'
pin 'flowbite-datepicker', to: 'https://cdnjs.cloudflare.com/ajax/libs/flowbite/1.6.4/datepicker.turbo.min.js'
pin '@sindresorhus/slugify', to: 'https://ga.jspm.io/npm:@sindresorhus/slugify@2.2.0/index.js'
pin '@sindresorhus/transliterate', to: 'https://ga.jspm.io/npm:@sindresorhus/transliterate@1.6.0/index.js'
pin 'escape-string-regexp', to: 'https://ga.jspm.io/npm:escape-string-regexp@5.0.0/index.js'
