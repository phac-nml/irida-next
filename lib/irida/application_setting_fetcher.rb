# frozen_string_literal: true

module Irida
  # ApplicationSettingFetcher is responsible for fetching the current application settings from the database.
  # It provides a stable interface for accessing these settings across the application, allowing other components to
  # retrieve the current settings without needing to know the details of how they are stored or accessed.
  module ApplicationSettingFetcher
    class << self
      def current_application_settings
        application_settings
      end

      def current_application_settings?
        ::ApplicationSetting.current.present?
      end

      private

      def application_settings
        current_settings = ::ApplicationSetting.current

        current_settings.presence || ::ApplicationSetting.create_from_defaults
      end
    end
  end
end
