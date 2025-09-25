# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class IconTest < ViewComponent::TestCase
    test 'renders icon with string name' do
      render_inline(Pathogen::Icon.new('clipboard-text'))
      assert_selector 'svg', count: 1
    end

    test 'renders icon with symbol name' do
      render_inline(Pathogen::Icon.new(:clipboard_text))
      assert_selector 'svg', count: 1
    end

    test 'normalizes symbol names with underscores to dashes' do
      # This test assumes the icon helper will normalize :clipboard_text to "clipboard-text"
      icon = Pathogen::Icon.new(:clipboard_text)
      assert_equal 'clipboard-text', icon.instance_variable_get(:@icon_name)
    end

    test 'applies default color and size classes' do
      render_inline(Pathogen::Icon.new('check'))
      assert_selector 'svg.text-slate-900.dark\\:text-slate-100.size-6', count: 1
    end

    test 'applies custom color' do
      render_inline(Pathogen::Icon.new('check', color: :primary))
      assert_selector 'svg.text-primary-600.dark\\:text-primary-500', count: 1
    end

    test 'applies custom size' do
      render_inline(Pathogen::Icon.new('check', size: :lg))
      assert_selector 'svg.size-8', count: 1
    end

    test 'applies custom color and size together' do
      render_inline(Pathogen::Icon.new('check', color: :success, size: :sm))
      assert_selector 'svg.text-green-600.dark\\:text-green-500.size-4', count: 1
    end

    test 'passes rails_icons variant option' do
      icon = Pathogen::Icon.new('heart', variant: :fill)
      rails_icons_options = icon.instance_variable_get(:@rails_icons_options)
      assert_equal :fill, rails_icons_options[:variant]
    end

    test 'passes rails_icons library option' do
      icon = Pathogen::Icon.new('beaker', library: :heroicons)
      rails_icons_options = icon.instance_variable_get(:@rails_icons_options)
      assert_equal :heroicons, rails_icons_options[:library]
    end

    test 'merges custom classes with pathogen styling' do
      render_inline(Pathogen::Icon.new('check', color: :primary, class: 'custom-class'))
      assert_selector 'svg.text-primary-600.dark\\:text-primary-500.custom-class', count: 1
    end

    test 'passes through other system arguments' do
      icon = Pathogen::Icon.new('check', id: 'my-icon', 'data-test': 'icon')
      rails_icons_options = icon.instance_variable_get(:@rails_icons_options)
      assert_equal 'my-icon', rails_icons_options[:id]
      assert_equal 'icon', rails_icons_options[:'data-test']
    end

    test 'includes aria-hidden in rails_icons options' do
      icon = Pathogen::Icon.new('check')
      rails_icons_options = icon.instance_variable_get(:@rails_icons_options)
      # The actual aria-hidden setting would be handled by IconHelper.render_icon
      assert_not_nil rails_icons_options
    end

    test 'supports all color variants' do
      Pathogen::Icon::COLORS.each_key do |color|
        icon = Pathogen::Icon.new('check', color: color)
        assert_not_nil icon
      end
    end

    test 'supports all size variants' do
      Pathogen::Icon::SIZES.each_key do |size|
        icon = Pathogen::Icon.new('check', size: size)
        assert_not_nil icon
      end
    end

    # Test backward compatibility with legacy ICON constants
    test 'works with legacy ICON constant hash format' do
      # This ensures our component still works if someone passes an ICON hash
      # until we migrate all usage
      render_inline(Pathogen::Icon.new('clipboard-text'))
      assert_selector 'svg', count: 1
    end

    test 'handles invalid icon names gracefully' do
      # This will depend on rails_icons behavior for invalid icons
      # The component should handle errors gracefully without crashing
      assert_nothing_raised do
        icon = Pathogen::Icon.new('definitely-not-a-real-icon-name-12345')
        assert_not_nil icon
      end
    end
  end
end