# frozen_string_literal: true

require 'view_component_test_case'

class NamespaceStatisticComponentTest < ViewComponentTestCase
  # Helper for translated labels
  delegate :t, to: :I18n

  test 'renders default (slate) color scheme with correct icon, label, and count' do
    label_key = 'components.project_dashboard.information.number_of_automated_workflow_executions'
    label = t(label_key)
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'total-projects',
                    icon_name: 'user_circle',
                    label: label,
                    count: 123,
                    color_scheme: :default
                  ))

    # Icon, label, and count
    assert_selector 'svg'
    assert_selector '[id$="-label-unified"]', text: label
    assert_selector '[aria-describedby$="-label-unified"]', text: '123'
  end

  test 'renders blue color scheme with correct Tailwind classes' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'blue-stats',
                    icon_name: 'user_circle',
                    label: t('components.project_dashboard.information.number_of_automated_workflow_executions'),
                    count: 456,
                    color_scheme: :blue
                  ))
    assert_selector '[class*="bg-blue-100"]'
    assert_selector '[class*="text-blue-700"]'
    assert_selector '[class*="dark:bg-blue-700"]'
    assert_selector '[class*="dark:text-blue-200"]'
  end

  test 'renders teal color scheme with correct Tailwind classes' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'teal-stats',
                    icon_name: 'user_circle',
                    label: t('components.project_dashboard.information.number_of_automated_workflow_executions'),
                    count: 789,
                    color_scheme: :teal
                  ))
    assert_selector '[class*="bg-teal-100"]'
    assert_selector '[class*="text-teal-700"]'
    assert_selector '[class*="dark:bg-teal-700"]'
    assert_selector '[class*="dark:text-teal-200"]'
  end

  test 'renders indigo, fuchsia, and amber color schemes' do
    {
      indigo: {
        bg: 'bg-indigo-100', text: 'text-indigo-700', dark_bg: 'dark:bg-indigo-700', dark_text: 'dark:text-indigo-200'
      },
      fuchsia: {
        bg: 'bg-fuchsia-100', text: 'text-fuchsia-700',
        dark_bg: 'dark:bg-fuchsia-700', dark_text: 'dark:text-fuchsia-200'
      },
      amber: {
        bg: 'bg-amber-100', text: 'text-amber-700', dark_bg: 'dark:bg-amber-700', dark_text: 'dark:text-amber-200'
      }
    }.each do |scheme, classes|
      label = t(
        'components.project_dashboard.information.number_of_members'
      )
      render_inline(
        NamespaceStatisticComponent.new(
          id_prefix: "#{scheme}-stats",
          icon_name: 'user_circle',
          label: label,
          count: 101,
          color_scheme: scheme
        )
      )
      assert_selector "[class*='#{classes[:bg]}']"
      assert_selector "[class*='#{classes[:text]}']"
      assert_selector "[class*='#{classes[:dark_bg]}']"
      assert_selector "[class*='#{classes[:dark_text]}']"
    end
  end

  test 'renders icon using pathogen_icon' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'icon-test',
                    icon_name: 'user_circle',
                    label: 'Icon Test',
                    count: 1,
                    color_scheme: :blue
                  ))
    assert_selector 'svg'
    assert_selector '[class*="inline-flex"]'
  end

  test 'accessibility: ARIA and roles are present for label and count' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'a11y',
                    icon_name: 'user_circle',
                    label: 'A11y',
                    count: 7,
                    color_scheme: :blue
                  ))
    # Label ID
    assert_selector '[id$="-label-unified"]'
    # aria-describedby on count
    assert_selector '[aria-describedby$="-label-unified"]'
    # Region role
    assert_selector '[role=region]'
    # Icon is decorative
    assert_selector '[aria-hidden=true]'
  end

  test 'internationalization: renders translated label' do
    label_key = 'components.project_dashboard.information.number_of_members'
    label = t(label_key)
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'i18n',
                    icon_name: 'user_circle',
                    label: label,
                    count: 42,
                    color_scheme: :default
                  ))
    assert_text label
  end

  test 'renders with large numbers and zero' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'big',
                    icon_name: 'user_circle',
                    label: 'Big',
                    count: 10_000_000,
                    color_scheme: :default
                  ))
    assert_text '10,000,000'

    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'zero',
                    icon_name: 'user_circle',
                    label: 'Zero',
                    count: 0,
                    color_scheme: :default
                  ))
    assert_text '0'
  end

  test 'layout: single responsive layout with icon, label, and count' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'layout',
                    icon_name: 'user_circle',
                    label: 'Layout Test',
                    count: 999,
                    color_scheme: :default
                  ))

    # Single layout with flex
    assert_selector '.flex'
    # Icon, label, and count are present
    assert_selector 'svg'
    assert_selector 'h3', text: 'Layout Test'
    assert_text '999'
  end

  test 'ID generation methods produce correct format' do
    component = NamespaceStatisticComponent.new(
      id_prefix: 'test-stats',
      icon_name: 'user_circle',
      label: 'Test',
      count: 1,
      color_scheme: :blue
    )

    assert_equal 'test-stats-icon-sm', component.icon_id_sm
    assert_equal 'test-stats-icon-lg', component.icon_id_lg
    assert_equal 'test-stats-icon-unified', component.icon_id_unified
    assert_equal 'test-stats-label-lg', component.label_id_lg
    assert_equal 'test-stats-label-unified', component.label_id_unified
  end

  test 'handles id_prefix parameterization correctly' do
    component = NamespaceStatisticComponent.new(
      id_prefix: 'User Projects & Stats!',
      icon_name: 'user_circle',
      label: 'Test',
      count: 1,
      color_scheme: :blue
    )

    # Should be parameterized to remove special characters and spaces
    assert_equal 'user-projects-stats-label-unified', component.label_id_unified
  end

  test 'renders with symbol icon_name' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'symbol-test',
                    icon_name: :user_circle,
                    label: 'Symbol Test',
                    count: 42,
                    color_scheme: :blue
                  ))
    assert_selector 'svg'
    assert_text 'Symbol Test'
    assert_text '42'
  end

  test 'handles very long labels gracefully' do
    long_label = 'This is an extremely long label that might wrap to multiple lines and should be handled ' \
                 'gracefully by the component with proper text wrapping and accessibility considerations'
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'long-label',
                    icon_name: 'user_circle',
                    label: long_label,
                    count: 999,
                    color_scheme: :default
                  ))

    assert_text long_label
    assert_selector '.break-words' # Ensures text wrapping is applied
  end

  test 'handles negative numbers' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'negative',
                    icon_name: 'user_circle',
                    label: 'Negative Count',
                    count: -42,
                    color_scheme: :default
                  ))
    assert_text '-42'
  end

  test 'handles decimal numbers by converting to integer' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'decimal',
                    icon_name: 'user_circle',
                    label: 'Decimal Count',
                    count: 42.7,
                    color_scheme: :default
                  ))
    # Should format as integer with delimiter
    assert_text '42'
  end

  test 'renders unknown color scheme with default icon colors' do
    # Test that unknown color scheme falls back to default
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'unknown',
                    icon_name: 'user_circle',
                    label: 'Unknown Color',
                    count: 1,
                    color_scheme: :nonexistent_color
                  ))

    # Should render successfully but use default icon colors
    assert_selector 'svg'
    assert_text 'Unknown Color'
    # Should use default slate icon colors when unknown scheme is provided
    assert_selector '[class*="text-slate-700"]'
  end

  test 'icon has proper decorative aria-hidden attribute' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'aria-test',
                    icon_name: 'user_circle',
                    label: 'ARIA Test',
                    count: 1,
                    color_scheme: :blue
                  ))

    # Icon should be marked as decorative
    assert_selector 'svg[aria-hidden="true"]'
  end

  test 'uses proper semantic HTML structure' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'semantic',
                    icon_name: 'user_circle',
                    label: 'Semantic Test',
                    count: 123,
                    color_scheme: :blue
                  ))

    # Should use h3 for the label (proper heading hierarchy)
    assert_selector 'h3', text: 'Semantic Test'
    # Should use region role for the container
    assert_selector '[role="region"]'
    # Count should be properly associated with label
    assert_selector '[aria-describedby="semantic-label-unified"]'
  end

  test 'applies proper responsive and accessibility classes' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'classes',
                    icon_name: 'user_circle',
                    label: 'Classes Test',
                    count: 1,
                    color_scheme: :teal
                  ))

    # Layout classes
    assert_selector '.flex.items-start.gap-3' # Main flex layout
    assert_selector '.shrink-0' # Icon container
    assert_selector '.flex-1.min-w-0' # Content container
    assert_selector '.break-words' # Label text wrapping

    # Typography classes
    assert_selector '.font-mono.tracking-tight' # Count styling
    assert_selector '.text-sm.font-medium' # Label styling
  end
end
