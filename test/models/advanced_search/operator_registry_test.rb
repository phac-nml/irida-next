# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  class OperatorRegistryTest < ActiveSupport::TestCase
    test 'returns standard and enum operator values' do
      assert_includes OperatorRegistry.standard_operator_values, '='
      assert_includes OperatorRegistry.standard_operator_values, 'starts_with'
      assert_equal %w[= != in not_in], OperatorRegistry.enum_operator_values
    end

    test 'returns metadata operator groups and list/no-value operator subsets' do
      metadata_grouped_options = OperatorRegistry.metadata_grouped_options

      assert_equal 4, metadata_grouped_options.keys.count
      assert_equal %w[exists not_exists], OperatorRegistry.no_value_operator_values
      assert_includes OperatorRegistry.list_value_operator_values, 'in'
      assert_includes OperatorRegistry.list_value_operator_values, 'text_in'
    end

    test 'returns payload with metadata based on feature flag' do
      payload_with_metadata = OperatorRegistry.advanced_search_payload(metadata_operators_enabled: true)
      payload_without_metadata = OperatorRegistry.advanced_search_payload(metadata_operators_enabled: false)

      assert payload_with_metadata['metadata'].present?
      assert_not payload_without_metadata.key?('metadata')
      assert payload_with_metadata['standard'].present?
      assert payload_with_metadata['enum'].present?
    end

    test 'returns graphql operator mapping with expected values' do
      graphql_values = OperatorRegistry.sample_graphql_operators.to_h

      assert_equal '=', graphql_values['EQUALS']
      assert_equal 'not_in', graphql_values['NOT_IN']
      assert_nil graphql_values['STARTS_WITH']
    end
  end
end
