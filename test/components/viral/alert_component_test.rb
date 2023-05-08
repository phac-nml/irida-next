# frozen_string_literal: true

require 'test_helper'

class Viral::AlertComponentTest < ViewComponent::TestCase
  test 'notice alert' do
    render_inline(Viral::AlertComponent.new(message: 'This is a notice alert', type: 'notice'))
    assert_text 'This is a notice alert'
    assert_selector 'div[data-controller="viral--alert-component"]', count: 1
  end
end
