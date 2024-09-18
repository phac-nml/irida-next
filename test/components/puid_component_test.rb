# frozen_string_literal: true

require 'application_system_test_case'

class PuidComponentTest < ApplicationSystemTestCase
  def test_default
    visit('/rails/view_components/puid_component/default')
    assert_text '1234567890'
    find('button[data-clipboard-target="button"]').click
    assert_text I18n.t('components.clipboard.copied')
  end
end
