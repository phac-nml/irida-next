# frozen_string_literal: true

require 'view_component_test_case'

class NamespaceStatisticComponentTest < ViewComponentTestCase
  # Helper for translated labels
  delegate :t, to: :I18n

  test 'renders default (slate) color scheme with correct icon, label, and count (mobile and desktop)' do
    label_key = 'components.project_dashboard.information.number_of_automated_workflow_executions'
    label = t(label_key)
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'total-projects',
                    icon_name: 'user_circle',
                    label: label,
                    count: 123,
                    color_scheme: :default
                  ))

    # Mobile: icon, tooltip, count
    assert_selector '.md\\:hidden [id^=total-projects-icon-sm]' # icon span
    assert_selector '.md\\:hidden [id^=total-projects-icon-sm] svg'
    assert_selector '.md\\:hidden [aria-labelledby^=total-projects-icon-sm]', text: '123'
    assert_selector '.md\\:hidden [role=tooltip]', visible: :all
    assert_text label

    # Desktop: icon, label, count
    assert_selector '.md\\:block [id^=total-projects-icon-lg] svg'
    assert_selector '.md\\:block [id^=total-projects-label-lg]', text: label
    assert_selector '.md\\:block [aria-labelledby^="total-projects-icon-lg total-projects-label-lg"]', text: '123'
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

  test 'renders icon using helpers.render_icon' do
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

  test 'accessibility: ARIA and roles are present for icon, label, and count' do
    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'a11y',
                    icon_name: 'user_circle',
                    label: 'A11y',
                    count: 7,
                    color_scheme: :blue
                  ))
    # Icon and label IDs
    assert_selector '[id^=a11y-icon-lg]'
    assert_selector '[id^=a11y-label-lg]'
    # aria-labelledby on count
    assert_selector '[aria-labelledby^="a11y-icon-lg a11y-label-lg"]'
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
    assert_text '10000000'

    render_inline(NamespaceStatisticComponent.new(
                    id_prefix: 'zero',
                    icon_name: 'user_circle',
                    label: 'Zero',
                    count: 0,
                    color_scheme: :default
                  ))
    assert_text '0'
  end
end
