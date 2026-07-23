# frozen_string_literal: true

module Irida
  # Runtime view of admin-manageable experimental features.
  module SystemFeatureFlagsCatalog
    class << self
      def entries(locale: I18n.locale)
        ExperimentalFeatureCatalog.admin_entries(locale: locale).map do |catalog_entry|
          entry(catalog_entry)
        end
      end

      def fetch(feature_key, locale: I18n.locale)
        normalized_key = feature_key.to_s
        return unless admin_manageable?(normalized_key)

        entry(ExperimentalFeatureCatalog.fetch(normalized_key, locale: locale))
      end

      def admin_manageable?(feature_key)
        ExperimentalFeatureCatalog.fetch(feature_key)&.fetch(:admin_manageable, false) == true
      end

      def global_state(feature_key)
        case Flipper[feature_key.to_sym].state
        when :on
          'enabled'
        when :conditional
          'conditional'
        else
          'disabled'
        end
      end

      delegate :opt_in_state, to: :settings

      def gate_summary(feature_key)
        feature = Flipper[feature_key.to_sym]

        {
          'boolean' => feature.boolean_value ? 1 : 0,
          'actors' => feature.actors_value.size,
          'groups' => feature.groups_value.size,
          'percentage_of_actors' => feature.percentage_of_actors_value.to_i,
          'percentage_of_time' => feature.percentage_of_time_value.to_i,
          'expression' => feature.expression_value.present? ? 1 : 0
        }
      end

      private

      def entry(catalog_entry)
        feature_key = catalog_entry.fetch(:key)

        catalog_entry.merge(
          global_state: global_state(feature_key),
          opt_in_state: opt_in_state(feature_key),
          gate_summary: gate_summary(feature_key)
        )
      end

      def settings
        CurrentSettings.current_application_settings
      end
    end
  end
end
