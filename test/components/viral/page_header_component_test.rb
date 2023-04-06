# frozen_string_literal: true

require 'test_helper'

class PageHeaderComponentTest < ViewComponent::TestCase
  test 'renders header' do
    title = 'THIS IS THE TITLE'
    subtitle = 'THIS IS A SUBTITLE'
    render_inline(Viral::PageHeaderComponent.new(title:, subtitle:))

    assert_text title
    assert_text subtitle
  end

  test 'renders header with icon' do
    title = 'THIS IS THE TITLE'
    subtitle = 'THIS IS A SUBTITLE'
    render_inline(Viral::PageHeaderComponent.new(title:, subtitle:)) do |component|
      component.with_icon(name: 'beaker')
      component.with_buttons { 'BUTTONS' }
    end

    assert_text title
    assert_text 'BUTTONS'
  end
end
