# frozen_string_literal: true

# return unless Flipper.enabled?(:integration_access_token_generation)

# https://github.com/cyu/rack-cors
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
