# frozen_string_literal: true

require 'application_system_test_case'

module System
  class FormErrorSummaryComponentTest < ApplicationSystemTestCase
    test 'focus demo' do
      visit('rails/view_components/form_error_summary_component/focus_demo')

      assert_selector '[data-controller="form-error-summary"]', focused: true
      assert_selector 'div[data-controller="form-error-summary"][tabindex="-1"]'

      within '[data-controller="form-error-summary"]' do
        click_link "Email can't be blank"
      end
      assert_selector '#user_email', focused: true

      within '[data-controller="form-error-summary"]' do
        click_link 'Namespace required'
      end
      assert_selector '#namespace-select', focused: true

      assert_accessible
    end
  end
end
