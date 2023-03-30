# frozen_string_literal: true

require 'test_helper'

module Navigation
  class SectionComponentTest < ViewComponent::TestCase
    def test_renders_section_with_title
      render_inline Navigation::SectionComponent.new(title: 'Section title') do |section|
        section.with_item(label: 'Item title', url: '#', icon: 'home')
        section.with_item(label: 'Item title', url: '#', icon: 'beaker')
      end

      assert_text 'Section title'
      assert_selector 'ul' do
        assert_selector 'li', count: 2
      end
    end
  end
end
