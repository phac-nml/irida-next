# frozen_string_literal: true

module Irida
  # CurrentSettings provides a convenient interface for accessing the current application settings throughout the
  # application. It delegates method calls to the current ApplicationSetting instance, allowing other components to
  # access settings without needing to know the details of how they are stored or accessed. This module can be included
  # in any class or module that needs access to the current application settings.
  module CurrentSettings
    class << self
      delegate :current_application_settings, to: :'Irida::ApplicationSettingFetcher'

      delegate :current_application_settings?, to: :'Irida::ApplicationSettingFetcher'

      def method_missing(name, ...)
        application_settings = current_application_settings

        return application_settings.send(name, ...) if application_settings.respond_to?(name)

        super
      end

      def respond_to_missing?(name, include_private = false)
        current_application_settings.respond_to?(name, include_private) || super
      end
    end
  end
end
