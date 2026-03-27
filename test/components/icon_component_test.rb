# frozen_string_literal: true

require 'view_component_test_case'

class IconComponentTest < ViewComponentTestCase
  class HelperProbeComponent < Component
    def call
      helpers.safe_join([
                          icon(:check, size: :sm, color: :primary),
                          icon(:x, size: :sm, color: :subdued)
                        ])
    end
  end

  test 'normalizes symbol icon names' do
    component = IconComponent.new(:clipboard_text)

    assert_equal 'clipboard-text', component.icon_name
  end

  test 'renders icon with default classes' do
    render_inline(IconComponent.new(:clipboard_text))

    assert_selector 'svg.clipboard-text-icon.size-6', count: 1
    assert_match(/text-slate-900/, page.native.to_html)
  end

  test 'applies custom color and size' do
    render_inline(IconComponent.new(:check, color: :success, size: :sm))

    assert_selector 'svg.check-icon.size-4', count: 1
    assert_match(/text-green-600/, page.native.to_html)
  end

  test 'merges custom classes' do
    render_inline(IconComponent.new(:check, color: :primary, class: 'custom-class'))

    assert_selector 'svg.custom-class.check-icon', count: 1
    assert_match(/text-primary-600/, page.native.to_html)
  end

  test 'supports classes alias' do
    render_inline(IconComponent.new(:info, classes: 'inline-icon'))

    assert_selector 'svg.inline-icon.info-icon', count: 1
  end

  test 'falls back to default color and size for unknown values' do
    component = IconComponent.new(:check, color: :unknown_color, size: :unknown_size)

    assert_equal :default, component.color
    assert_equal :md, component.size

    render_inline(component)

    assert_selector 'svg.size-6', count: 1
    assert_match(/text-slate-900/, page.native.to_html)
  end

  test 'allows opting out of default color classes' do
    render_inline(IconComponent.new(:check, color: nil, class: 'text-purple-500 fill-purple-500'))

    assert_selector 'svg.text-purple-500.fill-purple-500.check-icon', count: 1
    assert_no_match(/text-slate-900/, page.native.to_html)
    assert_no_match(/fill-slate-900/, page.native.to_html)
  end

  test 'raises an error when icon name is nil or blank' do
    assert_raises(ArgumentError) { IconComponent.new(nil) }
    assert_raises(ArgumentError) { IconComponent.new('') }
    assert_raises(ArgumentError) { IconComponent.new('   ') }
  end

  test 'icon helper renders app component in a view context' do
    html = vc_test_controller.view_context.icon(:check, size: :sm, color: :primary)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)

    assert_equal 1, fragment.css('svg.check-icon.size-4').count
    assert_includes fragment.to_html, 'text-primary-600'
  end

  test 'icon helper resolves to the app component in a component context' do
    render_inline(HelperProbeComponent.new)

    assert_selector 'svg', count: 2
    assert_selector 'svg.check-icon', count: 1
    assert_selector 'svg.x-icon', count: 1
  end

  test 'falls back to question-mark icon when primary icon rendering fails' do
    component = IconComponent.new(:missing_icon)
    icon_calls = []

    component.define_singleton_method(:native_rails_icon) do |name, **|
      icon_calls << name
      raise StandardError, 'missing icon' if name == 'missing-icon'

      '<svg class="fallback-icon" data=""></svg>'
    end

    render_inline(component)

    assert_equal %w[missing-icon question-mark-circle], icon_calls
    assert_selector 'svg.fallback-icon', count: 1
    assert_no_match(/data=/, page.native.to_html)
  end

  test 'returns nil when icon and fallback icons all fail outside local env' do
    component = IconComponent.new(:missing_icon)

    component.define_singleton_method(:native_rails_icon) do |_name, **|
      raise StandardError, 'missing icon'
    end

    with_rails_env('staging') do
      assert_nothing_raised do
        render_inline(component)
      end
    end

    assert_no_selector 'svg'
    assert_equal '', rendered_content.strip
  end

  test 'renders development error indicator when all icon rendering fails in local env' do
    component = IconComponent.new(:check_unknown)

    component.define_singleton_method(:native_rails_icon) do |_name, **|
      raise StandardError, 'missing icon'
    end

    with_rails_env('development') do
      assert_nothing_raised do
        render_inline(component)
      end
    end

    assert_text "Icon 'check-unknown' not found"
    assert_text 'Suggestions: check, check-circle, check-badge'
    assert_selector 'span.text-red-500', count: 1
  end

  test 'does not append icon name class in production' do
    component = nil

    with_rails_env('production') do
      component = IconComponent.new(:check)
      render_inline(component)
    end

    assert_selector 'svg.size-6', count: 1
    assert_no_selector 'svg.check-icon'
  end

  private

  def with_rails_env(name)
    original_env = Rails.env
    Rails.singleton_class.send(:define_method, :env) { ActiveSupport::EnvironmentInquirer.new(name) }
    yield
  ensure
    Rails.singleton_class.send(:define_method, :env) { original_env }
  end
end
