# frozen_string_literal: true

require 'application_system_test_case'

class TitleTooltipSystemTest < ApplicationSystemTestCase
  test 'truncated breadcrumb exposes its full name on hover and keyboard focus' do
    page.driver.with_playwright_page { |browser| browser.viewport_size = { width: 320, height: 640 } }
    visit '/rails/view_components/breadcrumb_component/with_crumbs'

    trigger = find('[aria-current="page"]')
    tooltip = "##{trigger['aria-describedby']}"
    assert_selector '[data-breadcrumb-target="crumb"].truncate'
    assert_no_selector '[aria-current="page"][title]'

    trigger.hover
    assert_selector "#{tooltip}[data-state='open']", text: trigger.text
    assert_selector "#pathogen-tooltip-portal #{tooltip}"
    find('body').send_keys(:escape)
    assert_selector "#{tooltip}[data-state='closed'][hidden]", visible: :all

    page.driver.with_playwright_page { |browser| browser.mouse.move(310, 600) }
    # Tab from the overflow menu button to the current page, without opening the menu.
    find('[data-breadcrumb-target="dropdownMenu"] button').send_keys(:tab)
    assert_selector '[aria-current="page"]:focus-visible'
    assert_selector "#{tooltip}[data-state='open']", text: trigger.text
    assert_component_accessible
    capture_tooltip('breadcrumb-tooltip-light')

    page.execute_script("document.documentElement.classList.add('dark')")
    capture_tooltip('breadcrumb-tooltip-dark')
    trigger.send_keys(:escape)
    assert_selector "#{tooltip}[data-state='closed'][hidden]", visible: :all
    assert_selector '[aria-current="page"]:focus'

    page.driver.with_playwright_page { |browser| browser.viewport_size = { width: 1280, height: 1024 } }
    assert_no_selector '[data-breadcrumb-target="crumb"].truncate'
    assert_no_selector '[aria-current="page"][title]'

    page.execute_script('Turbo.visit(window.location.href)')
    assert_no_selector tooltip, visible: :all
    find('[aria-current="page"]').hover
    assert_selector '#pathogen-tooltip-portal [role="tooltip"][data-state="open"]', count: 1
  end

  %w[v1 v2].each do |version|
    test "#{version} URL prefix exposes the full URL and preserves select keyboard operation" do
      Flipper.public_send(version == 'v2' ? :enable : :disable, :v2_prefixed_select2)
      visit '/rails/view_components/prefixed_select2_component/default'

      trigger = find('[data-pathogen--tooltip-target="trigger"]')
      tooltip = "##{trigger['aria-describedby']}"
      trigger.hover
      assert_selector "#{tooltip}[data-state='open']", text: trigger.text
      find('body').send_keys(:escape)
      assert_selector "#{tooltip}[data-state='closed'][hidden]", visible: :all

      find('label').hover
      find('input.select2-input').send_keys(%i[shift tab])
      assert_selector '[data-pathogen--tooltip-target="trigger"]:focus-visible'
      assert_selector "#{tooltip}[data-state='open']", text: trigger.text
      assert_component_accessible
      capture_tooltip("url-prefix-tooltip-#{version}")
      trigger.send_keys(:tab)
      assert_selector 'input.select2-input:focus'
      assert_selector "#{tooltip}[data-state='closed'][hidden]", visible: :all
      assert_no_selector '[data-pathogen--tooltip-target="trigger"][title]'
    end
  end

  private

  def capture_tooltip(name)
    page.driver.with_playwright_page do |browser|
      browser.screenshot(path: Rails.root.join("tmp/capybara/#{name}.png").to_s)
    end
  end
end
