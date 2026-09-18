# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module V2
    class DialogComponentTest < ViewComponent::TestCase
      test 'renders the v2 dialog host and host-agnostic builder' do
        render_preview(:v2_empty, from: AdvancedSearchComponentPreview)

        # Host adapter root + dialog lifecycle controller
        assert_selector "div#advanced-search[data-controller='advanced-search--v2--dialog']"
        # Host-agnostic builder element (outlet target for the dialog + search field)
        assert_selector "div#advanced-search-builder[data-controller='advanced-search--v2--builder']"

        # Trigger opens via the dialog controller, not the builder
        assert_selector "button[data-action='advanced-search--v2--dialog#renderSearch viral--dialog#open']",
                        text: I18n.t('components.advanced_search_component.v1.title')
      end

      %i[en fr].each do |locale|
        [false, true].each do |metadata_operators|
          test "dialog owns the original help in #{locale} with metadata operators #{metadata_operators}" do
            Flipper.enable(:advanced_search_metadata_operators) if metadata_operators
            Flipper.disable(:advanced_search_metadata_operators) unless metadata_operators

            I18n.with_locale(locale) do
              render_preview(:v2_empty, from: AdvancedSearchComponentPreview)

              description = I18n.t('components.advanced_search_component.v1.description')
              rule = metadata_operators ? 'metadata_operators' : 'standard_operators'
              other_rule = metadata_operators ? 'standard_operators' : 'metadata_operators'
              rules = I18n.t("components.advanced_search_component.v1.rules.#{rule}")

              assert_selector 'dialog p', text: description, visible: :all
              assert_selector 'dialog p', text: rules, visible: :all
              assert_no_selector 'dialog p',
                                 text: I18n.t("components.advanced_search_component.v1.rules.#{other_rule}"),
                                 visible: :all
              assert_no_selector '#advanced-search-builder p', text: description, visible: :all
              assert_no_selector '#advanced-search-builder p', text: rules, visible: :all
            end
          end
        end
      end

      %i[default empty workflow].each do |preview|
        test "#{preview} preview stays on v1 when v2 is enabled" do
          Flipper.enable(:advanced_search_v2)

          render_preview(preview, from: AdvancedSearchComponentPreview)

          assert_selector "div#advanced-search[data-controller='advanced-search--v1']"
          assert_no_selector "[data-controller='advanced-search--v2--dialog']", visible: :all
          assert_no_selector '#advanced-search-builder', visible: :all
        end
      end

      test 'standalone builder preview has no dialog or dialog help' do
        render_preview(:v2_builder, from: AdvancedSearchComponentPreview)

        assert_selector "form #advanced-search-builder[data-controller='advanced-search--v2--builder']"
        assert_no_selector 'dialog', visible: :all
        assert_no_selector 'p', text: I18n.t('components.advanced_search_component.v1.description'), visible: :all
        %w[standard_operators metadata_operators].each do |rule|
          assert_no_selector 'p', text: I18n.t("components.advanced_search_component.v1.rules.#{rule}"), visible: :all
        end
      end

      test 'builder exposes the client-side templates the controller needs' do
        render_preview(:v2_empty, from: AdvancedSearchComponentPreview)

        %w[
          searchGroupsTemplate conditionTemplate groupTemplate valueTemplate
          betweenValueTemplate selectValueTemplate listValueTemplate
          listSelectValueTemplate emptySearchTemplate
        ].each do |target|
          assert_selector "template[data-advanced-search--v2--builder-target='#{target}']", visible: :all
        end
      end

      test 'builder provides saved query values before list inputs initialize' do
        render_preview(:v2_list, from: AdvancedSearchComponentPreview)

        builder = page.find('#advanced-search-builder', visible: :all)
        state = builder['data-advanced-search--v2--builder-initial-state-value']

        assert_equal [[{ 'field' => 'metadata.country', 'operator' => 'in', 'values' => %w[Canada Mexico] }]],
                     JSON.parse(state)
      end

      test 'renders existing groups into the searchGroupsTemplate' do
        search = Sample::Query.new(
          groups: [
            Sample::SearchGroup.new(
              conditions: [Sample::SearchCondition.new(field: 'metadata.country', operator: '=', value: 'Canada')]
            ),
            Sample::SearchGroup.new(
              conditions: [Sample::SearchCondition.new(field: 'metadata.outbreak_code', operator: '=', value: 'X')]
            )
          ]
        )
        fields = AdvancedSearch::Fields.for_samples(sample_fields: %w[name], metadata_fields: %w[country outbreak_code])
        form = ActionView::Helpers::FormBuilder.new(:q, search, ActionController::Base.new.view_context, {})

        # Assert on the raw rendered string: <template> content is not reliably serialized
        # through Capybara's parsed node, so the two existing-group legends would be dropped.
        html = ApplicationController.render(
          AdvancedSearch::V2::BuilderComponent.new(form:, search:, fields:), layout: false
        )
        assert_includes html, I18n.t('components.advanced_search_component.v1.group', index: 1)
        assert_includes html, I18n.t('components.advanced_search_component.v1.group', index: 2)
      end
    end
  end
end
