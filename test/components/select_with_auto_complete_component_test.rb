# frozen_string_literal: true

require 'application_system_test_case'

class SelectWithAutoCompleteComponentTest < ApplicationSystemTestCase
  def test_default # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
          find("div[role='option'][data-value='metadata.patient_age']").click
          assert_equal 'patient_age', combobox.value
        end
      end
      hidden = find("input[type='hidden']", visible: false)
      assert_equal 'metadata.patient_age', hidden.value
    end
  end

  def test_enter_key
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.send_keys(:down, :down, :enter)
      assert_selector "div[role='listbox']", visible: false
      assert_equal 'patient_age', combobox.value
      hidden = find("input[type='hidden']", visible: false)
      assert_equal 'metadata.patient_age', hidden.value
    end
  end

  def test_alt_and_down_combination_keys
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.send_keys(%i[alt down])
      assert_selector "div[role='listbox']", visible: true
      first_option = all("div[role='option']")[0]
      assert_nil first_option['aria-selected']
    end
  end

  def test_down_and_up_keys
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.send_keys(:down, :down, :down)
      options = all("div[role='option']")
      first_option = options.first
      assert_equal first_option[:id], combobox['aria-activedescendant']
      combobox.send_keys(:up)
      last_option = options.last
      assert_equal last_option[:id], combobox['aria-activedescendant']
    end
  end

  def test_right_and_left_keys
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.send_keys(:left, :left, :right)
      cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
      assert_equal 2, cursor_position
    end
  end

  def test_home_and_end_keys
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.send_keys(:home)
      cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
      assert_equal 0, cursor_position
      combobox.send_keys(:end)
      cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
      assert_equal 3, cursor_position
    end
  end

  def test_escape_key
    visit('/rails/view_components/select_with_auto_complete_component/default')
    within "div[data-controller='select-with-auto-complete']" do
      combobox = find("input[role='combobox']")
      combobox.click
      listbox = find("div[role='listbox']")
      assert_matches_style(listbox, 'display' => 'block')
      assert_equal 'age', combobox.value
      combobox.send_keys(:escape, :escape)
      assert_matches_style(listbox, 'display' => 'none')
      assert_empty combobox.value
      hidden = find("input[type='hidden']", visible: false)
      assert_empty hidden.value
    end
  end
end
