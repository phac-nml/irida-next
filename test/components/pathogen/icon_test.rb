# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class IconTest < ViewComponent::TestCase
    test 'renders an icon' do
      render_inline(Pathogen::Icon.new(icon: 'user'))
      assert_icon 'user'
    end

    test 'renders with custom class' do
      render_inline(Pathogen::Icon.new(icon: 'user', class: 'custom-class'))
      assert_selector 'svg.custom-class'
    end

    test 'renders with custom size' do
      render_inline(Pathogen::Icon.new(icon: 'user', size: '2rem'))
      assert_selector 'svg[style*="width: 2rem"]'
      assert_selector 'svg[style*="height: 2rem"]'
    end

    test 'renders with variant' do
      render_inline(Pathogen::Icon.new(icon: 'user', variant: :bold))
      assert_selector 'svg[data-phosphor-icon-variant="bold"]'
    end

    test 'renders with data attributes' do
      render_inline(Pathogen::Icon.new(icon: 'user', data: { controller: 'test' }))
      assert_selector 'svg[data-controller="test"]'
    end
  end
end
