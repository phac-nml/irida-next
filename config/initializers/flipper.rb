# frozen_string_literal: true

FLIPPER_FEATURE_CONFIG = YAML.safe_load(Rails.root.join('config/features.yml').read)

Rails.application.configure do
  config.flipper.memoize = ->(request) { !request.path.start_with?('/assets') }
end

Rails.application.reloader.to_prepare do # rubocop:disable Metrics/BlockLength
  Flipper::UI.configure do |config|
    config.feature_creation_enabled = false
    config.feature_removal_enabled = false
    config.show_feature_description_in_list = true
    config.confirm_disable = true
    config.confirm_fully_enable = true
    config.descriptions_source = lambda do |_keys|
      FLIPPER_FEATURE_CONFIG['features'].transform_values { |value| value['description'] }
    end
  end

  Rails.application.config.after_initialize do
    # Make sure that each feature we reference in code is present in the UI, as long as we have a Database already
    added_flippers = []
    begin
      FLIPPER_FEATURE_CONFIG['features'].each do |feature, feature_config|
        unless Flipper.exist?(feature)
          Flipper.add(feature)
          added_flippers.push(feature)
        end

        # Default features to enable for test and those explicitly set for development
        if Rails.env.test? || (Rails.env.development? && feature_config['enable_in_development'])
          Flipper.enable(feature)
        end
      end

      unless added_flippers.empty?
        Rails.logger.info "The following feature flippers were added: #{added_flippers.join(', ')}"
      end
      removed_features = Flipper.features.collect(&:name) - FLIPPER_FEATURE_CONFIG['features'].keys
      unless removed_features.empty?
        Rails.logger.warn "Consider removing features no longer in config/features.yml: #{removed_features.join(', ')}"
      end
    rescue StandardError => e
      Rails.logger.error "Error processing Flipper features: #{e.message}"
      # make sure we can still run rake tasks before table has been created
      nil
    end
  end
end
