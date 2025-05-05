require 'test_helper'

# 🧪 Tests for IconHelper
# Ensures icons are rendered correctly based on the ICONS registry.
class IconHelperTest < ActionView::TestCase
  include IconHelper

  # Stub the icon method that would normally be provided by a view helper
  # This simulates what the actual icon helper would return in the application
  def icon(name, **options)
    options_str = options.map do |key, value|
      if value.is_a?(Hash)
        # Handle nested hashes like data: { foo: 'bar' }
        nested_attrs = value.map { |k, v| "data-#{k}=\"#{v}\"" }.join(' ')
        nested_attrs
      else
        "#{key}=\"#{value}\""
      end
    end.join(' ')

    # Return a simple, predictable HTML structure for testing
    "<div data-icon=\"#{name}\" #{options_str}>Icon: #{name}</div>".html_safe
  end

  # Test that render_icon returns nil for unknown icon key
  test 'returns nil for unknown icon key' do
    result = render_icon(:non_existent_icon_key_12345)
    assert_nil result, 'Should return nil when the icon key is not found in ICONS registry'
  end

  # Test rendering a default icon mapping (:irida_logo -> :flask)
  test 'renders icon from DEFAULTS mapping' do
    result = render_icon(:irida_logo)
    assert result.present?, 'Should return HTML for irida_logo icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Basic structure validation
    expected_icon_name, = ICONS[:irida_logo]
    assert_match(/data-icon="#{expected_icon_name}"/, result,
                 "Should include the icon name '#{expected_icon_name}' in the output")
  end

  # Test rendering a Phosphor icon
  test 'renders icon from PHOSPHOR set' do
    result = render_icon(:clipboard)
    assert result.present?, 'Should return HTML for clipboard icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Validate that the icon name is included in the output
    expected_icon_name, = ICONS[:clipboard]
    assert_match(/data-icon="#{expected_icon_name}"/, result,
                 "Should include the icon name '#{expected_icon_name}' in the output")
  end

  # Test rendering a Heroicon icon
  test 'renders icon from HEROICONS set' do
    result = render_icon(:beaker)
    assert result.present?, 'Should return HTML for beaker icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Validate that the icon name is included in the output
    expected_icon_name, = ICONS[:beaker]
    assert_match(/data-icon="#{expected_icon_name}"/, result,
                 "Should include the icon name '#{expected_icon_name}' in the output")
  end

  # Test rendering an icon with additional CSS classes
  test 'renders icon with additional CSS classes' do
    additional_class = 'text-red-500'
    result = render_icon(:clipboard, class: additional_class)

    assert result.present?, 'Should return HTML with the additional class'
    assert_match(/class="#{additional_class}"/, result, 'Rendered HTML should contain the additional class')
  end

  # Test rendering an icon with additional HTML attributes
  test 'renders icon with additional HTML attributes' do
    data_testid = 'clipboard-icon'
    result = render_icon(:clipboard, data: { testid: data_testid })

    assert result.present?, 'Should return HTML with the additional attributes'
    assert_match(/data-testid="#{data_testid}"/, result, 'Rendered HTML should contain the data attribute')
  end

  # Test that ICONS registry correctly returns icon definitions
  test 'ICONS registry returns correct icon definitions' do
    # Check a few different icon types
    assert_not_nil ICONS[:irida_logo], 'ICONS registry should contain irida_logo'
    assert_not_nil ICONS[:clipboard], 'ICONS registry should contain clipboard'
    assert_not_nil ICONS[:beaker], 'ICONS registry should contain beaker'

    # Validate the structure (array with name and options)
    name, options = ICONS[:beaker]
    assert_equal :beaker, name, 'Icon name should be :beaker'
    assert_equal :heroicons, options[:library], 'Icon library should be :heroicons'
    assert_equal :solid, options[:variant], 'Icon variant should be :solid'
  end
end
