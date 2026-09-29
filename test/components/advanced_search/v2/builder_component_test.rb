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

      %i[en fr].each do |locale|
        test "renders accessible group help and translated dividers in #{locale}" do
          I18n.with_locale(locale) do
            search = Sample::Query.new(groups: [Sample::SearchGroup.new])
            html = Nokogiri::HTML.fragment(render_builder(search:))
            groups = html.css("fieldset[data-advanced-search--v2--builder-target='groupsContainer']")
            assert_equal 2, groups.size # Existing group plus the new-group template.
            groups.each do |group|
              helper = html.at_css("[id='#{group['aria-describedby']}']")
              assert_equal I18n.t('components.advanced_search_component.v2.group_match_all'), helper.text.strip
              assert_nil helper['aria-hidden']
            end
            %w[and or].each do |connective|
              divider = html.at_css("[data-advanced-search-connective='#{connective}']")
              assert_equal I18n.t("components.advanced_search_component.v2.connective.#{connective}"),
                           divider.text.strip
              assert_equal 'true', divider['aria-hidden']
              assert_empty divider.css('[name]')
            end
          end
        end
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
                        translation_key: 'components.advanced_search_component.operations.standard' }
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

      test 'restricts created_at operator options to date operators only' do
        search = Attachment::Query.new(
          groups: [
            Attachment::SearchGroup.new(
              conditions: [
                Attachment::SearchCondition.new(field: 'created_at', operator: '=', value: '2024-01-01'),
                Attachment::SearchCondition.new(field: 'filename', operator: 'contains', value: 'fastq')
              ]
            )
          ]
        )
        fields = AdvancedSearch::Fields.for_attachments

        html = render_builder(search:, fields:)
        fragment = Nokogiri::HTML::DocumentFragment.parse(html)

        created_at_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="created_at"]')
        filename_fieldset = fragment.at_css('fieldset[data-advanced-search-selected-field="filename"]')
        datepicker = created_at_fieldset.at_css('[data-controller]')

        created_at_operator_values =
          created_at_fieldset.css('select[name*="[operator]"] option').map { |o| o['value'] } # rubocop:disable Rails/Pluck
        filename_operator_values = filename_fieldset.css('select[name*="[operator]"] option').map { |o| o['value'] } # rubocop:disable Rails/Pluck

        assert_not_includes created_at_operator_values, 'contains'
        assert_not_includes created_at_operator_values, 'in'
        assert_includes created_at_operator_values, 'between'
        assert_includes filename_operator_values, 'contains'
        assert_equal 'combobox-datepicker--v1--input', datepicker['data-controller']
      end
    end
  end
end
