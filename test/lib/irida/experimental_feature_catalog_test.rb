# frozen_string_literal: true

require 'test_helper'

module Irida
  class ExperimentalFeatureCatalogTest < ActiveSupport::TestCase
    test 'returns admin-manageable features in configuration order' do
      entries = ExperimentalFeatureCatalog.admin_entries

      assert_equal %w[
        accessibility_statement
        advanced_search_disable_standard_operators_for_metadata_in_graphql
        advanced_search_metadata_operators
        advanced_search_with_auto_complete
        client_linelist_exports_v1
        client_linelist_imports_v1
        data_grid_samples_table
        global_groups
        v2_dropdown
        v2_prefixed_select2
        v2_samplesheet
        v2_select2
      ], entries.pluck(:key)
    end

    test 'excludes operational features from admin entries' do
      keys = ExperimentalFeatureCatalog.admin_entries.pluck(:key)

      assert_not_includes keys, 'compose_with_retry'
      assert_not_includes keys, 'integration_access_token_generation'
    end

    test 'returns localized names and descriptions with english fallback' do
      I18n.with_locale(:fr) do
        entry = ExperimentalFeatureCatalog.fetch(:data_grid_samples_table)

        assert_equal 'Tableau de données des échantillons', entry[:name]
        assert_equal 'Activer la nouvelle grille de données pour le tableau des échantillons.', entry[:description]
      end

      entry = ExperimentalFeatureCatalog.fetch(:data_grid_samples_table, locale: :es)

      assert_equal 'Data Grid Samples Table', entry[:name]
      assert_equal 'Enable the new data grid for the samples table.', entry[:description]
    end

    test 'admin-manageable features have complete english and french copy' do
      configured_features = FLIPPER_FEATURE_CONFIG.fetch('features')

      configured_features.each do |key, config|
        next unless config['admin_manageable']

        assert config.dig('name', 'en').present?, "#{key} is missing an English name"
        assert config.dig('name', 'fr').present?, "#{key} is missing a French name"
        assert config.dig('description', 'en').present?, "#{key} is missing an English description"
        assert config.dig('description', 'fr').present?, "#{key} is missing a French description"
      end
    end

    test 'returns nil for unknown features' do
      assert_nil ExperimentalFeatureCatalog.fetch(:unknown_feature)
    end
  end
end
