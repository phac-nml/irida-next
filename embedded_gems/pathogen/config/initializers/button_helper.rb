# frozen_string_literal: true

# This initializer ensures the button helper is included in ActionView
Rails.application.config.after_initialize do
  ActiveSupport.on_load(:action_view) do
    include Pathogen::ButtonHelper
  end
end
