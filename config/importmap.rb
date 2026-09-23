# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Enable integrity calculation for all pins
enable_integrity!

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'pathogen_view_components', to: 'pathogen_view_components.js'
pin 'pathogen_view_components/data_grid_controller', to: 'pathogen_view_components/data_grid_controller.js'
pin 'pathogen_view_components/data_grid_controller/navigation',
    to: 'pathogen_view_components/data_grid_controller/navigation.js'
pin 'pathogen_view_components/data_grid_controller/page_cache',
    to: 'pathogen_view_components/data_grid_controller/page_cache.js'
pin 'pathogen_view_components/data_grid_controller/page_source',
    to: 'pathogen_view_components/data_grid_controller/page_source.js'
pin 'pathogen_view_components/data_grid_controller/paginated_virtual_rows',
    to: 'pathogen_view_components/data_grid_controller/paginated_virtual_rows.js'
pin 'pathogen_view_components/data_grid_controller/pagination_mode',
    to: 'pathogen_view_components/data_grid_controller/pagination_mode.js'
pin 'pathogen_view_components/data_grid_controller/scroll',
    to: 'pathogen_view_components/data_grid_controller/scroll.js'
pin 'pathogen_view_components/data_grid_controller/virtual_columns',
    to: 'pathogen_view_components/data_grid_controller/virtual_columns.js'
pin 'pathogen_view_components/data_grid_controller/virtualizer',
    to: 'pathogen_view_components/data_grid_controller/virtualizer.js'
pin 'pathogen_view_components/data_grid_controller/virtual_window',
    to: 'pathogen_view_components/data_grid_controller/virtual_window.js'
pin 'pathogen_view_components/data_grid_controller/widget_mode',
    to: 'pathogen_view_components/data_grid_controller/widget_mode.js'
pin 'pathogen_view_components/disclosure_controller', to: 'pathogen_view_components/disclosure_controller.js'
pin 'pathogen_view_components/sidebar_controller', to: 'pathogen_view_components/sidebar_controller.js'
pin 'pathogen_view_components/tabs_controller', to: 'pathogen_view_components/tabs_controller.js'
pin 'pathogen_view_components/toolbar_controller', to: 'pathogen_view_components/toolbar_controller.js'
pin 'pathogen_view_components/toolbar_controller/constants',
    to: 'pathogen_view_components/toolbar_controller/constants.js'
pin 'pathogen_view_components/toolbar_controller/roving_focus',
    to: 'pathogen_view_components/toolbar_controller/roving_focus.js'
pin 'pathogen_view_components/toolbar_controller/text_entry',
    to: 'pathogen_view_components/toolbar_controller/text_entry.js'
pin 'pathogen_view_components/toolbar_controller/visibility',
    to: 'pathogen_view_components/toolbar_controller/visibility.js'
pin 'pathogen_view_components/tooltip_controller', to: 'pathogen_view_components/tooltip_controller.js'

pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.7/dist/esm/index.js'
pin '@floating-ui/dom', to: 'https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.8.0/+esm'
pin '@floating-ui/core', to: 'https://cdn.jsdelivr.net/npm/@floating-ui/core@1.8.0/+esm'
pin '@floating-ui/utils', to: 'https://cdn.jsdelivr.net/npm/@floating-ui/utils@0.2.12/+esm'
pin '@floating-ui/utils/dom', to: 'https://cdn.jsdelivr.net/npm/@floating-ui/utils@0.2.12/dom/+esm'
pin '@sindresorhus/slugify', to: '@sindresorhus--slugify.js' # @2.2.1
pin '@sindresorhus/transliterate', to: '@sindresorhus--transliterate.js' # @1.6.0
pin 'escape-string-regexp' # @5.0.0
pin '@rails/activestorage', to: '@rails--activestorage.js' # @8.1.200
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/workers', under: 'workers'
pin 'xlsx', to: 'https://cdn.sheetjs.com/xlsx-0.20.3/package/xlsx.mjs'
pin_all_from 'app/javascript/utilities', under: 'utilities'
pin 'local-time' # @3.0.2
pin 'focus-trap' # @7.6.5
pin 'tabbable' # @6.2.0
pin 'uuid' # @14.0.0
pin 'debounce' # @3.0.0
pin 'deepmerge' # @4.3.1
