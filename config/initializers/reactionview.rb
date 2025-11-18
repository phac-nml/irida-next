# frozen_string_literal: true

if defined?(ReActionView)
  ReActionView.configure do |config|
    # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
    config.intercept_erb = true

    # Enable debug mode in development (adds debug attributes to HTML)
    config.debug_mode = Rails.env.development?

    # Add custom transform visitors to process templates before compilation
    # config.transform_visitors = [
    #   Herb::Visitor::new
    # ]
  end
end
