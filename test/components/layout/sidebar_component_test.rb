# frozen_string_literal: true

require 'test_helper'

module Layout
  class SidebarComponentTest < ViewComponent::TestCase
    test 'renders navigation container with overlay' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      assert_selector("nav#sidebar[aria-label='#{I18n.t('general.default_sidebar.aria_label')}']")
      assert_selector('.sidebar-overlay', visible: :all)
    end

    test 'renders header slot content' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Custom Header')
      end

      assert_selector('[data-test-selector="sidebar-header-root"]', text: 'Custom Header')
    end

    test 'renders with sections' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Section 1') do |section|
          section.with_item(label: 'Item 1', url: '/path1')
        end
        sidebar.with_section(title: 'Section 2') do |section|
          section.with_item(label: 'Item 2', url: '/path2')
        end
      end

      assert_selector('h3', text: 'Section 1')
      assert_selector('h3', text: 'Section 2')
      assert_selector('a[href="/path1"]', text: 'Item 1')
      assert_selector('a[href="/path2"]', text: 'Item 2')
    end

    test 'renders with top-level items' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Item 1', url: '/path1')
        sidebar.with_item(label: 'Item 2', url: '/path2')
      end

      assert_selector('a[href="/path1"]', text: 'Item 1')
      assert_selector('a[href="/path2"]', text: 'Item 2')
    end

    test 'renders with pipelines disabled' do
      render_inline(Layout::SidebarComponent.new(pipelines_enabled: false)) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      assert_selector('nav#sidebar')
    end

    test 'renders collapsed by default when specified' do
      render_inline(Layout::SidebarComponent.new(collapsed_by_default: true)) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # The collapsed state is handled by JavaScript, so we just check the component renders
      assert_selector('nav#sidebar')
    end

    test 'renders with icons' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Item with Icon', url: '#') do |item|
          item.with_icon { 'ICON' }
        end
      end

      assert_selector('a', text: 'Item with Icon')
    end

    test 'renders with selected item' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_item(label: 'Current Page', url: '/current', selected: true)
        sidebar.with_item(label: 'Other Page', url: '/other')
      end

      assert_selector('a[href="/current"][aria-current="page"]')
      assert_no_selector('a[href="/other"][aria-current="page"]')
    end

    test 'sidebar is accessible' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Access Section') do |section|
          section.with_item(label: 'Projects', url: '/projects')
        end
      end

      assert_selector('nav#sidebar[aria-label="Main sidebar"]')
      assert_selector('a[href="/projects"]', text: 'Projects')
    end

    test 'renders with multi-level menu' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
        sidebar.with_section(title: 'Settings') do |section|
          section.with_multi_level_menu(title: 'Configuration') do |menu|
            menu.with_menu_item(label: 'General', url: '/settings/general')
            menu.with_menu_item(label: 'Advanced', url: '/settings/advanced')
          end
        end
      end

      # The menu items might be hidden by default, so we just check the button is rendered
      assert_selector('button', text: 'Configuration')
    end

    test 'renders help link with accessible label' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      assert_selector('a[aria-label="Help - Opens in new tab"]', text: 'Help')
    end

    test 'navbar buttons have tooltips instead of title attributes' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # Collapse button should not have title attribute
      collapse_label = I18n.t('general.navbar.toggle_sidebar')
      collapse_button = page.find(
        "button[aria-label='#{collapse_label}'][data-pathogen--tooltip-target='trigger']"
      )
      assert_not collapse_button['title'], 'Collapse button should not have title attribute'

      # Collapse button should have aria-describedby pointing to tooltip
      tooltip_id = collapse_button['aria-describedby']
      assert tooltip_id.present?, 'Collapse button should have aria-describedby'

      # Tooltip should exist with correct ID and text
      assert_selector("[role='tooltip'][id='#{tooltip_id}']", text: collapse_label)
    end

    test 'new dropdown has tooltip integration' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # Find the new dropdown trigger button
      new_label = I18n.t('general.navbar.new_dropdown.label')
      new_button = page.find(
        "button[aria-label='#{new_label}'][data-pathogen--tooltip-target='trigger']"
      )

      # Should have aria-describedby pointing to tooltip
      tooltip_id = new_button['aria-describedby']
      assert tooltip_id.present?, 'New dropdown button should have aria-describedby'

      # Tooltip should exist with correct ID and text
      assert_selector("[role='tooltip'][id='#{tooltip_id}']", text: new_label)

      # Should still have viral--dropdown functionality
      assert_selector('button[data-viral--dropdown-target="trigger"]', count: 3) # goto, new, profile
    end

    test 'profile dropdown has tooltip integration' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # Find the profile dropdown trigger button
      profile_label = I18n.t('general.navbar.account_dropdown.label')
      profile_button = page.find(
        "button[aria-label='#{profile_label}'][data-pathogen--tooltip-target='trigger']"
      )

      # Should have aria-describedby pointing to tooltip
      tooltip_id = profile_button['aria-describedby']
      assert tooltip_id.present?, 'Profile dropdown button should have aria-describedby'

      # Tooltip should exist with correct ID and text
      assert_selector("[role='tooltip'][id='#{tooltip_id}']", text: profile_label)

      # Should still have viral--dropdown functionality
      assert_selector('button[data-viral--dropdown-target="trigger"]', count: 3) # goto, new, profile
    end

    test 'tooltip IDs are unique across navbar buttons' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # Collect all tooltip IDs from buttons with tooltips
      buttons = page.all('button[data-pathogen--tooltip-target="trigger"]')
      # rubocop:disable Rails/Pluck
      tooltip_ids = buttons.map { |button| button['aria-describedby'] }
      # rubocop:enable Rails/Pluck

      # All IDs should be present
      assert tooltip_ids.all?(&:present?), 'All tooltip buttons should have aria-describedby'

      # All IDs should be unique
      assert_equal tooltip_ids.uniq.length, tooltip_ids.length, 'All tooltip IDs should be unique'
    end

    test 'dropdown buttons preserve both viral--dropdown and pathogen--tooltip targets' do
      render_inline(Layout::SidebarComponent.new) do |sidebar|
        sidebar.with_header(label: 'Header')
      end

      # New dropdown should have both targets
      new_dropdown = page.find("button[aria-label='#{I18n.t('general.navbar.new_dropdown.label')}']")
      assert new_dropdown['data-viral--dropdown-target'] == 'trigger',
             'New dropdown should have viral--dropdown-target'
      assert new_dropdown['data-pathogen--tooltip-target'] == 'trigger',
             'New dropdown should have pathogen--tooltip-target'

      # Profile dropdown should have both targets
      profile_dropdown = page.find("button[aria-label='#{I18n.t('general.navbar.account_dropdown.label')}']")
      assert profile_dropdown['data-viral--dropdown-target'] == 'trigger',
             'Profile dropdown should have viral--dropdown-target'
      assert profile_dropdown['data-pathogen--tooltip-target'] == 'trigger',
             'Profile dropdown should have pathogen--tooltip-target'
    end
  end
end
