# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.configuration.cors_config['origins']

    Rails.configuration.cors_config['resources'].each do |entry|
      resource entry[:resource],
               headers: entry[:headers].to_sym,
               methods: entry[:methods].map(&:to_sym)
    end
  end
end
