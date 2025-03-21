# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class CardComponentTest < ViewComponentTestCase
    test 'default card' do
      render_preview(:default)

      assert_selector 'section.viral-card' do
        assert_selector 'h2.font-semibold' do
          assert_text 'Simple card with Title'
        end
        assert_text 'This is the content of the card'
      end
    end

    test 'card with header actions' do
      render_preview(:section_with_action)

      assert_selector 'section.viral-card' do
        assert_selector 'h2', text: 'Card with section actions'
        assert_selector '.viral-card-section', count: 1 do
          assert_selector 'h3', text: 'FIRST SECTION'
          assert_selector 'a.text-red-500', text: 'Delete'
        end
      end
    end

    test 'card with simple header' do
      render_preview(:simple_header)

      assert_selector 'section.viral-card' do
        assert_text 'Card with a simple header'
      end
    end

    test 'card with multiple sections' do
      render_preview(:with_multiple_sections)

      assert_selector 'section.viral-card' do
        assert_selector 'h2', text: 'Card with multiple sections'
        assert_selector '.viral-card-section', count: 2
        assert_selector 'h3', text: 'SECTION 1'
        assert_selector 'h3', text: 'SECTION 2'
      end
    end

    test 'card section with action' do
      render_preview(:section_with_action)

      assert_selector 'section.viral-card' do
        assert_selector '.viral-card-section', count: 1
        assert_selector 'h3', text: 'FIRST SECTION'
        assert_selector 'a', text: 'Delete'
      end
    end
  end
end
