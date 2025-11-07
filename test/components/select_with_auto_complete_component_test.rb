# frozen_string_literal: true

require 'application_system_test_case'

class SelectWithAutoCompleteComponentTest < ApplicationSystemTestCase
  def test_default # rubocop:disable Metrics/MethodLength
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      assert_equal 'age', combobox.value
      assert_equal 'false', combobox['aria-expanded']
      combobox.click
      assert_equal 'true', combobox['aria-expanded']
      listbox = find("div[role='listbox']")
      within listbox do
        group = find("div[role='group']")
        within group do
          assert_selector "div[role='presentation']", text: 'Metadata fields'
          assert_selector "div[role='option'][data-value='metadata.age']"
          assert_selector "div[role='option'][data-value='metadata.patient_age']"
        end
      end
    end
  end
end
