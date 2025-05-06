require 'test_helper'

# Tests for IconHelper
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
    "<div data-test-selector=\"#{name}\" #{options_str}>Icon: #{name}</div>".html_safe
  end

  # Test that render_icon returns nil for unknown icon key
  test 'returns nil for unknown icon key' do
    result = render_icon(:non_existent_icon_key_12345)
    assert_nil result, 'Should return nil when the icon key is not found in ICONS registry'
  end

  # Test rendering a default icon mapping (:irida_logo -> :beaker)
  test 'renders icon from DEFAULTS mapping' do
    result = render_icon(:irida_logo)
    assert result.present?, 'Should return HTML for irida_logo icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Basic structure validation
    assert_match(/data-test-selector="beaker"/, result,
                 "Should include the icon name 'beaker' in the output")
    assert_match(/data-test-selector="irida_logo"/, result,
                 "Should include the test selector 'irida_logo' in the output")
  end

  # Test rendering a Phosphor icon
  test 'renders icon from PHOSPHOR set' do
    result = render_icon(:clipboard)
    assert result.present?, 'Should return HTML for clipboard icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Validate that the icon name is included in the output
    assert_match(/data-test-selector="clipboard-text"/, result,
                 "Should include the icon name 'clipboard-text' in the output")
    assert_match(/data-test-selector="clipboard"/, result,
                 "Should include the test selector 'clipboard' in the output")
  end

  # Test rendering a Heroicon icon
  test 'renders icon from HEROICONS set' do
    result = render_icon(:beaker)
    assert result.present?, 'Should return HTML for beaker icon'
    assert result.html_safe?, 'Result should be HTML safe'

    # Validate that the icon name is included in the output
    assert_match(/data-test-selector="beaker"/, result,
                 "Should include both the icon name and test selector 'beaker' in the output")
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

    # Validate the structure (hash with :name and :options keys)
    icon_def = ICONS[:beaker]
    assert_equal :beaker, icon_def[:name], 'Icon name should be :beaker'
    assert_equal :heroicons, icon_def[:options][:library], 'Icon library should be :heroicons'
    
    # Check irida_logo definition
    icon_def = ICONS[:irida_logo]
    assert_equal :beaker, icon_def[:name], 'irida_logo icon name should be :beaker'
    assert_equal :heroicons, icon_def[:options][:library], 'irida_logo icon library should be :heroicons'
    assert_equal :solid, icon_def[:options][:variant], 'irida_logo icon variant should be :solid'
  end
  
  # Test the private methods through the public interface
  test 'private methods work correctly through render_icon' do
    # Test resolve_icon_definition through render_icon
    result = render_icon(ICONS[:clipboard])
    assert result.present?, 'Should handle a direct icon definition hash'
    
    # Test prepare_icon_options through render_icon with various options
    result = render_icon(:clipboard, class: 'custom-class', data: { testid: 'test' })
    assert_match(/class="custom-class"/, result, 'Should apply custom class')
    assert_match(/data-testid="test"/, result, 'Should apply data attributes')
  end
  
  # Test that test selectors are added in test environment
  test 'adds test selectors in test environment' do
    # The test environment is mocked in the icon method above
    result = render_icon(:clipboard)
    assert_match(/data-test-selector="clipboard"/, result, 'Should add test selector in test environment')
  end
end
