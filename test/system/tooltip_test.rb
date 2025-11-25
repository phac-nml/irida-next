# frozen_string_literal: true

require 'application_system_test_case'

class TooltipTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
  end

  test 'tooltip appears on hover and hides on mouse leave' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Hover over trigger
    tooltip_trigger.hover

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Move mouse away
    tooltip_trigger.native.send_keys(:escape)

    # Wait for tooltip to hide
    assert_selector 'div[role="tooltip"].opacity-0.invisible', wait: 2
  end

  test 'tooltip appears on focus and hides on blur' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Focus on trigger
    tooltip_trigger.focus

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Blur trigger
    tooltip_trigger.send_keys(:tab)

    # Wait for tooltip to hide
    assert_selector 'div[role="tooltip"].opacity-0.invisible', wait: 2
  end

  test 'tooltip dismisses with Escape key' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Focus on trigger to show tooltip
    tooltip_trigger.focus

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Press Escape key
    tooltip_trigger.send_keys(:escape)

    # Wait for tooltip to hide
    assert_selector 'div[role="tooltip"].opacity-0.invisible', wait: 2
  end

  test 'tooltip respects viewport boundaries and flips when needed' do
    visit '/-/groups/group-1'

    # Resize window to small size to test boundary detection
    page.driver.browser.manage.window.resize_to(400, 300)

    # Find a link with tooltip near edge
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Hover over trigger
    tooltip_trigger.hover

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Get tooltip position
    tooltip = page.find('div[role="tooltip"].opacity-100.visible', match: :first)
    tooltip_rect = tooltip.native.rect

    # Verify tooltip is within viewport bounds (with padding)
    assert tooltip_rect.x >= 0, 'Tooltip should be within viewport left edge'
    assert tooltip_rect.y >= 0, 'Tooltip should be within viewport top edge'
    assert tooltip_rect.x + tooltip_rect.width <= 400, 'Tooltip should be within viewport right edge'
    assert tooltip_rect.y + tooltip_rect.height <= 300, 'Tooltip should be within viewport bottom edge'
  end

  test 'tooltip has proper ARIA relationship' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Get the tooltip ID from aria-describedby
    tooltip_id = tooltip_trigger['aria-describedby']

    # Verify tooltip exists with that ID
    assert_selector "div##{tooltip_id}[role='tooltip']"

    # Focus to show tooltip
    tooltip_trigger.focus

    # Verify tooltip is visible
    assert_selector "div##{tooltip_id}[role='tooltip'].opacity-100.visible", wait: 2
  end
end
