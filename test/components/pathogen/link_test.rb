# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class LinkTest < ViewComponent::TestCase
    def test_renders_as_a_link
      url = 'http://irida-next.com'
      link_text = 'content'
      render_inline(Pathogen::Link.new(href: url)) { link_text }
      assert_component_rendered
      assert_selector "a[href='#{url}']", text: link_text
    end
  end
end
