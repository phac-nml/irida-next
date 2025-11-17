# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

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

# Pathogen controllers (from embedded gem or external gem)
# Use a single pin_all_from to expose all controllers under "controllers/pathogen"
# Pathogen gem controllers - explicit pinning to ensure asset path resolution across engines
pathogen_controllers_path = Pathogen::ViewComponents::Engine.root.join('app/assets/javascripts/pathogen/controllers')
Dir.glob(pathogen_controllers_path.join('**/*.js')).each do |file|
	name = file.delete_prefix(pathogen_controllers_path.to_s + '/').delete_suffix('.js')
	# Map Stimulus identifier pathogen--foo--bar => controllers/pathogen/foo/bar_controller
	pin "controllers/pathogen/#{name}", to: "pathogen/controllers/#{name}.js", preload: false
end

pin 'xlsx' # @0.18.5
pin_all_from 'app/javascript/utilities', under: 'utilities'
pin 'sortablejs' # @1.15.2
pin 'local-time' # @3.0.2
pin 'lodash' # @4.17.21
pin 'focus-trap' # @7.6.5
pin 'tabbable' # @6.2.0
pin 'uuid' # @13.0.0
