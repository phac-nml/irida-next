# frozen_string_literal: true

RailsIcons.configure do |config|
  config.default_library = 'phosphor'
  # config.default_variant = "" # Set a default variant for all libraries

  # Override Phosphor defaults - explicitly set data to nil to prevent empty data attributes
  config.libraries.phosphor.regular.default.data = nil
  config.libraries.phosphor.fill.default.data = nil
  config.libraries.phosphor.duotone.default.data = nil
  config.libraries.phosphor.bold.default.data = nil
  config.libraries.phosphor.light.default.data = nil
  config.libraries.phosphor.thin.default.data = nil

  # Override Heroicon defaults - explicitly set data to nil to prevent empty data attributes
  config.libraries.heroicons.outline.default.data = nil
  config.libraries.heroicons.solid.default.data = nil
  config.libraries.heroicons.mini.default.data = nil
  config.libraries.heroicons.micro.default.data = nil
end
