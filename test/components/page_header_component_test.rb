# frozen_string_literal: true

require 'test_helper'

class PageHeaderComponentTest < ViewComponent::TestCase
  def test_renders_header
    title = 'THIS IS THE TITLE'
    subtitle = 'THIS IS A SUBTITLE'
    render_inline(PageHeaderComponent.new(title:, subtitle:))

    assert_text title
    assert_text subtitle
  end
end
