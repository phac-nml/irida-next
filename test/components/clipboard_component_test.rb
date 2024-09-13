# frozen_string_literal: true

require 'application_system_test_case'

class ClipboardComponentTest < ApplicationSystemTestCase
  def test_default
    visit('/rails/view_components/clipboard_component/default')
    assert_text 'Value to copy'
    find('button[data-clipboard-target="button"]').click
    assert_text I18n.t('components.clipboard.copied')
  end

  def test_custom_content
    visit('/rails/view_components/clipboard_component/custom_content')
    assert_selector 'span.bg-orange-100', text: 'INXT_GRP_AYJFZ42CTQ'
    find('button[data-clipboard-target="button"]').click
    assert_text I18n.t('components.clipboard.copied')
  end
end
