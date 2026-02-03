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

    # Move mouse away by hovering over a different element (body)
    page.find('body').hover

    # Wait for tooltip to hide (don't use visible: filter since element is invisible)
    assert_selector 'div[role="tooltip"].opacity-0.invisible', visible: :all, wait: 2
  end

  test 'tooltip appears on focus and hides on blur' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Focus on trigger using JavaScript
    page.execute_script('arguments[0].focus()', tooltip_trigger)

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Blur trigger by focusing on body
    page.execute_script('document.body.focus()')

    # Wait for tooltip to hide (don't use visible: filter since element is invisible)
    assert_selector 'div[role="tooltip"].opacity-0.invisible', visible: :all, wait: 2
  end

  test 'tooltip dismisses with Escape key' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Focus on trigger to show tooltip using JavaScript
    page.execute_script('arguments[0].focus()', tooltip_trigger)

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Press Escape key (send to body since the handler is on document)
    page.find('body').send_keys(:escape)

    # Wait for tooltip to hide (don't use visible: filter since element is invisible)
    assert_selector 'div[role="tooltip"].opacity-0.invisible', visible: :all, wait: 2
  end

  test 'tooltip respects viewport boundaries and flips when needed' do
    visit '/-/groups/group-1'

    # Resize window to small size to test boundary detection (Cuprite syntax)
    page.driver.resize(400, 300)

    # Find a link with tooltip near edge
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Hover over trigger
    tooltip_trigger.hover

    # Wait for tooltip to appear
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2

    # Get tooltip position
    tooltip = page.find('div[role="tooltip"].opacity-100.visible', match: :first)
    tooltip_rect = page.evaluate_script('arguments[0].getBoundingClientRect().toJSON()', tooltip)

    # Verify tooltip is within viewport bounds (with padding)
    assert tooltip_rect['x'].to_f >= 0, 'Tooltip should be within viewport left edge'
    assert tooltip_rect['y'].to_f >= 0, 'Tooltip should be within viewport top edge'
    assert tooltip_rect['x'].to_f + tooltip_rect['width'].to_f <= 400, 'Tooltip should be within viewport right edge'
    assert tooltip_rect['y'].to_f + tooltip_rect['height'].to_f <= 300, 'Tooltip should be within viewport bottom edge'
  end

  test 'tooltip has proper ARIA relationship' do
    visit '/-/groups/group-1'

    # Find a link with tooltip
    tooltip_trigger = page.find('a[aria-describedby]', match: :first)

    # Get the tooltip ID from aria-describedby
    tooltip_id = tooltip_trigger['aria-describedby']

    # Verify tooltip exists with that ID (check all elements, not just visible)
    assert_selector "div##{tooltip_id}[role='tooltip']", visible: :all

    # Hover to show tooltip (use hover instead of focus since it's more reliable)
    tooltip_trigger.hover

    # Verify tooltip is visible
    assert_selector "div##{tooltip_id}[role='tooltip'].opacity-100.visible", wait: 2
  end

  test 'touch interaction shows tooltip on first tap' do
    visit '/-/groups/group-1'

    trigger = page.find('a[aria-describedby]', match: :first)

    # Simulate touch interaction - first tap should show tooltip
    page.execute_script(<<~JS, trigger)
      var trigger = arguments[0];
      // Dispatch touchstart to mark as touch interaction
      var touchEvent = new Event('touchstart', { bubbles: true, cancelable: true });
      trigger.dispatchEvent(touchEvent);
      // Dispatch click event (follows touchstart on mobile)
      var clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
      trigger.dispatchEvent(clickEvent);
    JS

    # Tooltip should be visible after first tap
    assert_selector 'div[role="tooltip"].opacity-100.visible', wait: 2
  end
end
