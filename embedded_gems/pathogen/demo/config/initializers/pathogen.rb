# frozen_string_literal: true

require 'pathogen/view_components'

# Use concat to create new arrays instead of modifying the existing ones
components_path = Rails.root.join('../app/components')
Rails.application.config.autoload_paths = Rails.application.config.autoload_paths.dup.concat([components_path])
Rails.application.config.eager_load_paths = Rails.application.config.eager_load_paths.dup.concat([components_path])
