# frozen_string_literal: true

require 'application_system_test_case'

class ClipboardComponentTest < ApplicationSystemTestCase
  def test_default
    visit('/rails/view_components/clipboard_component/default')
    assert_text 'Value to copy'
    assert_button "Copy to clipboard value: 'Value to copy'"
    click_button "Copy to clipboard value: 'Value to copy'"
    assert_text I18n.t('components.clipboard.copied')
  end

  def test_custom_content
    visit('/rails/view_components/clipboard_component/custom_content')
    assert_selector 'span.bg-orange-100', text: 'INXT_GRP_AYJFZ42CTQ'
    assert_button 'Copy to clipboard value: "Different value"'
    click_button 'Copy to clipboard value: "Different value"'
    assert_text I18n.t('components.clipboard.copied')
  end
end
