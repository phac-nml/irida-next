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
                        text: I18n.t('components.advanced_search_component.v2.title')
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
        assert_includes html, I18n.t('components.advanced_search_component.v2.group', index: 1)
        assert_includes html, I18n.t('components.advanced_search_component.v2.group', index: 2)
      end
    end
  end
end
