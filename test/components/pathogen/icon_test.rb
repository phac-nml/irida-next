# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class IconTest < ViewComponent::TestCase
    class HelperProbeComponent < ::Component
      def initialize(icon_name, **kwargs)
        super()
        @icon_name = icon_name
        @kwargs = kwargs
      end

      def call
        icon(@icon_name, **@kwargs)
      end
    end

    test 'icon renders through app icon component' do
      render_inline(HelperProbeComponent.new(:clipboard_text))

      assert_selector 'svg.clipboard-text-icon', count: 1
    end

    test 'icon applies default color and size classes' do
      render_inline(HelperProbeComponent.new(:check))

      assert_selector 'svg.size-6', count: 1
      assert_match(/text-slate-900/, page.native.to_html)
    end

    test 'icon applies custom color and size classes' do
      render_inline(HelperProbeComponent.new(:check, color: :success, size: :sm))

      assert_selector 'svg.check-icon.size-4', count: 1
      assert_match(/text-green-600/, page.native.to_html)
    end

    test 'icon supports variant and library pass-through' do
      component = IconComponent.new(:beaker, variant: :fill, library: :heroicons)

      assert_equal :fill, component.rails_icons_options[:variant]
      assert_equal :heroicons, component.rails_icons_options[:library]
    end

    test 'icon merges custom classes and supports nil color opt-out' do
      render_inline(HelperProbeComponent.new(:check, color: nil, class: 'text-purple-500 fill-purple-500 custom-class'))

      assert_selector 'svg.custom-class.check-icon', count: 1
      assert_no_match(/text-slate-900/, page.native.to_html)
      assert_no_match(/fill-slate-900/, page.native.to_html)
    end

    test 'icon handles invalid names without raising' do
      assert_nothing_raised do
        render_inline(HelperProbeComponent.new(:definitely_not_a_real_icon_name))
      end
    end
  end
end
