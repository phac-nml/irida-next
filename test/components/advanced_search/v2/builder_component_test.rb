# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module V2
    class BuilderComponentTest < ViewComponent::TestCase
      def build_form(search)
        ActionView::Helpers::FormBuilder.new(:q, search, ActionController::Base.new.view_context, {})
      end

      def render_builder(search:, fields: nil, sample_fields: [], metadata_fields: [])
        ApplicationController.render(
          AdvancedSearch::V2::BuilderComponent.new(
            form: build_form(search), search:, fields:, sample_fields:, metadata_fields:
          ),
          layout: false
        )
      end

      test 'derives sample fields when no explicit fields are provided' do
        search = Sample::Query.new(
          groups: [Sample::SearchGroup.new(conditions: [Sample::SearchCondition.new(field: 'name', operator: '=',
                                                                                    value: 'sample')])]
        )

        html = render_builder(search:, fields: nil, sample_fields: %w[name], metadata_fields: %w[country])

        assert_includes html, 'advanced-search--v2--builder-target="conditionTemplate"'
        assert_includes html, 'metadata.country'
      end

      test 'renders enum value options and enum operators for enum fields' do
        Flipper.enable(:advanced_search_metadata_operators)
        search = Sample::Query.new(
          groups: [
            Sample::SearchGroup.new(
              conditions: [
                Sample::SearchCondition.new(field: 'metadata.country', operator: 'text_in', value: %w[Canada]),
                Sample::SearchCondition.new(field: 'name', operator: 'in', value: %w[alpha]),
                Sample::SearchCondition.new(field: 'metadata.notes', operator: 'text_equals', value: 'note')
              ]
            )
          ]
        )
        fields = AdvancedSearch::Fields.build(
          options: [%w[Name name]],
          groups: {},
          enum_fields: {
            'metadata.country' => { values: %w[Canada Mexico], labels: { 'Canada' => 'Canada Label' } },
            'name' => { values: %w[alpha],
                        translation_key: 'components.advanced_search_component.v1.operations.standard' }
          }
        )

        html = render_builder(search:, fields:)

        # labels branch, humanize fallback branch, and translation_key branch of the enum label helper
        assert_includes html, 'Canada Label'
        assert_includes html, 'Mexico'
        assert_includes html, 'Alpha'
      end

      test 'renders grouped metadata operators for non-enum metadata fields' do
        Flipper.enable(:advanced_search_metadata_operators)
        search = Sample::Query.new(
          groups: [
            Sample::SearchGroup.new(
              conditions: [Sample::SearchCondition.new(field: 'metadata.notes', operator: 'text_equals',
                                                       value: 'note')]
            )
          ]
        )
        fields = AdvancedSearch::Fields.build(options: [], groups: {}, enum_fields: {})

        html = render_builder(search:, fields:)

        assert_includes html, 'optgroup'
      end

      test 'restricts byte_size operator options to numeric operators only' do
        search = Attachment::Query.new(
          groups: [
            Attachment::SearchGroup.new(
              conditions: [
                Attachment::SearchCondition.new(field: 'byte_size', operator: '=', value: '100'),
                Attachment::SearchCondition.new(field: 'filename', operator: 'contains', value: 'fastq')
              ]
            )
          ]
        )
        fields = AdvancedSearch::Fields.for_attachments

        html = render_builder(search:, fields:)
        fragment = Nokogiri::HTML::DocumentFragment.parse(html)

        byte_size_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="byte_size"]')
        filename_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="filename"]')

        byte_size_operator_values = byte_size_fieldset.css('select[name*="[operator]"] option').map { |o| o['value'] } # rubocop:disable Rails/Pluck
        filename_operator_values = filename_fieldset.css('select[name*="[operator]"] option').map { |o| o['value'] } # rubocop:disable Rails/Pluck

        assert_not_includes byte_size_operator_values, 'contains'
        assert_includes filename_operator_values, 'contains'
      end
    end
  end
end
