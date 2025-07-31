# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class ConditionalWrapperTest < ViewComponent::TestCase
    test 'wraps content when condition is true' do
      render_inline(Pathogen::ConditionalWrapper.new(condition: true, tag: :div, classes: 'outside')) do |component|
        component.content_tag(:span, class: 'inside') { 'Content' }
      end

      assert_selector 'div.outside span.inside', text: 'Content'
    end

    test 'does not wrap content when condition is false' do
      render_inline(Pathogen::ConditionalWrapper.new(condition: false, tag: :div, classes: 'outside')) do |component|
        component.content_tag(:span, class: 'inside') { 'Content' }
      end

      refute_selector 'div.outside span.inside'
      assert_selector 'span.inside', text: 'Content'
    end
  end
end
