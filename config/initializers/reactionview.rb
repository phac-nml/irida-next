# frozen_string_literal: true

ReActionView.configure do |config|
  # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
  config.intercept_erb = true

  # Enable debug mode in development (adds debug attributes to HTML)
  config.debug_mode = Rails.env.development? && ENV['HERB_DEBUG'].present?

  # TEMPORARY FIX while we wait for reactionview to fix .debug_mode
  # Disable validation mode in non-development environments so it doesn't inject <template> tags into emails
  config.validation_mode = Rails.env.development? ? :overlay : :none

  # Add custom transform visitors to process templates before compilation
  # config.transform_visitors = [
  #   Herb::Visitor::new
  # ]
end
