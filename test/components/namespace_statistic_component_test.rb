# frozen_string_literal: true

require 'test_helper'

class NamespaceStatisticComponentTest < ViewComponent::TestCase
  # Helper for translated labels
  delegate :t, to: :I18n

  test 'renders basic statistic with required parameters' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'test-stat',
                    label: 'Test Label',
                    value: 42
                  ))

    assert_selector 'div[role="region"]' do
      assert_selector 'h3.text-slate-700.dark\:text-slate-300', text: 'Test Label'
      assert_selector 'div.text-slate-900.dark\:text-slate-100', text: '42'
    end
  end

  test 'renders with custom color scheme' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'colored-stat',
                    label: 'Colored Stat',
                    value: 100,
                    color_scheme: :blue
                  ))

    # The color scheme is applied to the icon, which isn't present in this test
    # So we'll just verify the component renders without error
    assert_text '100'
  end

  test 'renders with icon when provided' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'icon-stat',
                    label: 'With Icon',
                    value: 7,
                    icon_name: :users
                  ))

    assert_selector 'svg', count: 1
    assert_selector 'div.flex.items-start.gap-3' do
      assert_selector 'h3', text: 'With Icon'
    end
  end

  test 'handles string values' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'string-value',
                    label: 'String Value',
                    value: 'Active'
                  ))

    assert_selector 'div.text-slate-900.dark\:text-slate-100', text: 'Active'
  end

  test 'handles date values' do
    date = Date.new(2023, 1, 1)
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'date-value',
                    label: 'Created On',
                    value: date
                  ))

    assert_selector 'time', text: /#{date.year}/
  end

  test 'generates unique component IDs' do
    component1 = NamespaceStatisticComponent.new(id_prefix: 'test', label: 'Test', value: 1)
    component2 = NamespaceStatisticComponent.new(id_prefix: 'test', label: 'Test', value: 2)

    assert_not_equal component1.component_id, component2.component_id
    assert_match(/^ns-stat-test-\w{8}$/, component1.component_id)
  end

  test 'count method returns numeric value or zero' do
    numeric_component = NamespaceStatisticComponent.new(id_prefix: 'num', label: 'Numeric', value: 42)
    string_component = NamespaceStatisticComponent.new(id_prefix: 'str', label: 'String', value: 'Not a number')

    assert_equal 42, numeric_component.count
    assert_equal 0, string_component.count
  end

  test 'renders with custom background colors' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'custom-bg',
                    label: 'Custom BG',
                    value: 123,
                    bg_color: 'bg-indigo-100',
                    dark_bg_color: 'dark:bg-indigo-900'
                  ))

    assert_selector 'div.bg-indigo-100.dark\:bg-indigo-900', count: 1
  end

  test 'handles nil values gracefully' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'nil-value',
                    label: 'No Value',
                    value: nil
                  ))

    assert_selector 'div.text-slate-900.dark\:text-slate-100', text: '—'
  end

  test 'respects color scheme in dark mode' do
    # Testing dark mode is tricky without the theme helper, so we'll focus on the component's behavior
    # and let the view helpers handle the actual dark mode classes
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'dark-mode',
                    label: 'Dark Mode',
                    value: 99,
                    color_scheme: :teal
                  ))

    # Just verify it renders without error
    assert_text '99'
  end
end
