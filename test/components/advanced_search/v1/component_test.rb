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
    end
  end
end
