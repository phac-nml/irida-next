# frozen_string_literal: true

RailsIcons.configure do |config|
  config.default_library = :phosphor
  config.default_variant = :regular

  # Override Phosphor defaults - ensure `data` attributes are omitted entirely
  config.libraries.phosphor.regular.default.data = {}
  config.libraries.phosphor.fill.default.data = {}
  config.libraries.phosphor.duotone.default.data = {}
  config.libraries.phosphor.bold.default.data = {}
  config.libraries.phosphor.light.default.data = {}
  config.libraries.phosphor.thin.default.data = {}

  # Override Heroicon defaults - ensure `data` attributes are omitted entirely
  config.libraries.heroicons.outline.default.data = {}
  config.libraries.heroicons.solid.default.data = {}
  config.libraries.heroicons.mini.default.data = {}
  config.libraries.heroicons.micro.default.data = {}
end
