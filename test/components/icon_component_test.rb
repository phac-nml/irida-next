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

  test 'allows opting out of default color classes' do
    render_inline(IconComponent.new(:check, color: nil, class: 'text-purple-500 fill-purple-500'))

    assert_selector 'svg.text-purple-500.fill-purple-500.check-icon', count: 1
    assert_no_match(/text-slate-900/, page.native.to_html)
    assert_no_match(/fill-slate-900/, page.native.to_html)
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
end
