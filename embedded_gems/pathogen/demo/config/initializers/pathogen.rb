require "pathogen/view_components"

# Configure Rails to autoload the components
Rails.application.config.autoload_paths << Rails.root.join("../app/components")
Rails.application.config.eager_load_paths << Rails.root.join("../app/components")
