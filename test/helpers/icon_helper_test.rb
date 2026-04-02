# frozen_string_literal: true

require 'view_component_test_case'

class IconHelperTest < ViewComponentTestCase
  delegate :view_context, to: :vc_test_controller

  test 'rails_icon renders native rails_icons output' do
    fragment = Nokogiri::HTML::DocumentFragment.parse(view_context.rails_icon(:check).to_s)

    assert_equal 1, fragment.css('svg').count
  end

  test 'icon renders app icon component output' do
    fragment = Nokogiri::HTML::DocumentFragment.parse(view_context.icon(:check, size: :sm, color: :primary).to_s)

    assert_equal 1, fragment.css('svg.check-icon.size-4').count
    assert_includes fragment.to_html, 'text-primary-600'
  end

  test 'icon helper accepts a block' do
    fragment = Nokogiri::HTML::DocumentFragment.parse(view_context.icon(:check, size: :sm) { 'ignored' }.to_s)

    assert_equal 1, fragment.css('svg.check-icon.size-4').count
  end
end
