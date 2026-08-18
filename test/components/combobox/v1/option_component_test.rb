# frozen_string_literal: true

require 'view_component_test_case'

module Combobox
  module V1
    class OptionComponentTest < ViewComponentTestCase
      test 'renders label when no content is provided' do
        render_inline(OptionComponent.new(value: 'user-1', label: 'User 1'))

        assert_selector '[role="option"][data-value="user-1"][data-label="User 1"]', text: 'User 1'
      end

      test 'renders aria-disabled when disabled is true' do
        render_inline(OptionComponent.new(value: 'user-2', label: 'User 2', disabled: true))

        assert_selector '[role="option"][data-value="user-2"][aria-disabled="true"]', text: 'User 2'
      end

      test 'renders block content when it differs from label' do
        render_inline(OptionComponent.new(value: 'user-3', label: 'User 3 label')) do
          '<span class="font-semibold">Visible user 3</span>'.html_safe
        end

        assert_selector '[role="option"][data-value="user-3"][data-label="User 3 label"] .font-semibold',
                        text: 'Visible user 3'
        assert_no_text 'User 3 label'
      end

      test 'renders explicit id when provided' do
        render_inline(OptionComponent.new(value: 'user-4', label: 'User 4', id: 'custom-option-id'))

        assert_selector '#custom-option-id[role="option"][data-value="user-4"]', text: 'User 4'
      end
    end
  end
end
