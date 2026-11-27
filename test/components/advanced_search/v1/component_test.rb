# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module V1
    class ComponentTest < ViewComponent::TestCase
      def build_form(search)
        ActionView::Helpers::FormBuilder.new(:q, search, ActionController::Base.new.view_context, {})
      end

      test 'renders datepickers for configured date fields' do
        search = Attachment::Query.new(
          groups: [
            Attachment::SearchGroup.new(
              conditions: [Attachment::SearchCondition.new(field: 'created_at', operator: '=', value: '2024-01-01')]
            )
          ]
        )

        html = ApplicationController.render(
          AdvancedSearch::V1::Component.new(form: build_form(search), search:, fields: AdvancedSearch::Fields.for_attachments),
          layout: false
        )
        fragment = Nokogiri::HTML::DocumentFragment.parse(html)
        created_at_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="created_at"]')
        datepicker = created_at_fieldset.at_css('[data-controller]')

        assert_equal 'combobox-datepicker--v1--input', datepicker['data-controller']
      end

      test 'uses standard enum operators for metadata enum fields when metadata operators are disabled' do
        Flipper.disable(:advanced_search_metadata_operators)

        search = Sample::Query.new(
          groups: [
            Sample::SearchGroup.new(
              conditions: [Sample::SearchCondition.new(field: 'metadata.country', operator: 'in', value: %w[Canada])]
            )
          ]
        )
        fields = AdvancedSearch::Fields.build(
          options: [%w[Country metadata.country]],
          groups: {},
          enum_fields: {
            'metadata.country' => { values: %w[Canada Mexico] }
          }
        )

        html = ApplicationController.render(
          AdvancedSearch::V1::Component.new(form: build_form(search), search:, fields:),
          layout: false
        )
        fragment = Nokogiri::HTML::DocumentFragment.parse(html)
        metadata_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="metadata.country"]')
        operator_values = metadata_fieldset.css('select[name*="[operator]"] option').map { |o| o['value'] } # rubocop:disable Rails/Pluck

        assert_not_empty operator_values
        assert_includes operator_values, 'in'
        assert_includes operator_values, 'not_in'
        assert_not_includes operator_values, 'text_equals'
      end
    end
  end
end
