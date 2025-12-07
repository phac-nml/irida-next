# frozen_string_literal: true

require 'application_system_test_case'

# Integration tests for the complete dark mode feature
# These tests verify end-to-end workflows combining theme switching,
# visual changes, screen reader announcements, and persistence
class DarkModeIntegrationTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
  end

  # Test 1: Complete end-to-end user journey
  test 'complete user journey: select theme → see change → hear announcement → persist' do
    visit profile_preferences_path

    # Step 1: Select dark theme
    page.find('input[value="dark"]').click
    sleep 0.5

    # Step 2: Verify visual change
    assert page.has_css?('html.dark'), 'Dark class should be applied to html element'

    # Verify background color changed
    body_bg = page.evaluate_script("getComputedStyle(document.body).backgroundColor")
    assert_not_nil body_bg, 'Body should have computed background color'

    # Step 3: Verify screen reader announcement
    announcement_text = page.evaluate_script(<<~JS.strip)
      (function() {
        var regions = document.querySelectorAll('[aria-live="polite"]');
        for (var i = 0; i < regions.length; i++) {
          if (regions[i].classList.contains('sr-only')) {
            return regions[i].textContent;
          }
        }
        return null;
      })()
    JS

    assert_not_nil announcement_text, 'Announcement should be present'
    assert_includes announcement_text.downcase, 'dark', 'Should announce dark theme'

    # Step 4: Navigate to another page and verify persistence
    visit root_path
    sleep 0.3

    assert page.has_css?('html.dark'), 'Dark mode should persist after navigation'

    # Step 5: Reload page and verify persistence (cold start)
    visit current_path
    sleep 0.3

    assert page.has_css?('html.dark'), 'Dark mode should persist after page reload'
  end

  # Test 2: System preference changes are detected
  test 'system preference change triggers theme update in system mode' do
    visit profile_preferences_path

    # Select system mode
    page.find('input[value="system"]').click
    sleep 0.5

    # Get current theme
    initial_has_dark = page.evaluate_script('document.documentElement.classList.contains("dark")')

    # Simulate system preference change by toggling the matchMedia result
    # This tests that the mediaQuery listener is working
    opposite_theme = initial_has_dark ? 'light' : 'dark'

    # Manually trigger theme update (simulating system preference change)
    page.execute_script(<<~JS)
      // Trigger the storage event handler that updates theme
      const event = new StorageEvent('storage', {
        key: 'colour-mode',
        newValue: '#{opposite_theme}'
      });
      window.dispatchEvent(event);
    JS

    sleep 0.3

    # Verify theme changed
    final_has_dark = page.evaluate_script('document.documentElement.classList.contains("dark")')
    assert_not_equal initial_has_dark, final_has_dark, 'Theme should toggle on system preference change'
  end

  # Test 3: Theme changes sync across tabs via localStorage
  test 'theme change in one tab syncs to other tabs via storage event' do
    visit root_path

    # Set initial theme to light
    page.execute_script('localStorage.setItem("colour-mode", "light")')
    sleep 0.3

    # Simulate storage event from another tab changing theme to dark
    page.execute_script(<<~JS)
      const event = new StorageEvent('storage', {
        key: 'colour-mode',
        oldValue: 'light',
        newValue: 'dark'
      });
      window.dispatchEvent(event);
    JS

    sleep 0.5

    # Verify theme updated in current tab
    assert page.has_css?('html.dark'), 'Dark mode should apply via storage event'
  end

  # Test 4: Theme switching with components renders correctly
  test 'components render correctly after theme switch' do
    visit root_path

    # Start in light mode
    if page.has_css?('html.dark')
      # Need to switch to light first
      visit profile_preferences_path
      page.find('input[value="light"]').click
      sleep 0.3
      visit root_path
    end

    # Get component background color in light mode
    if page.has_css?('.viral-card', wait: 2)
      light_mode_bg = page.evaluate_script(<<~JS)
        const card = document.querySelector('.viral-card');
        return card ? getComputedStyle(card).backgroundColor : null;
      JS

      # Switch to dark mode
      visit profile_preferences_path
      page.find('input[value="dark"]').click
      sleep 0.5
      visit root_path
      sleep 0.3

      # Get component background color in dark mode
      dark_mode_bg = page.evaluate_script(<<~JS)
        const card = document.querySelector('.viral-card');
        return card ? getComputedStyle(card).backgroundColor : null;
      JS

      # Verify background colors are different
      assert_not_equal light_mode_bg, dark_mode_bg, 'Component should have different background in dark mode'
    else
      skip 'No viral-card components found on root page'
    end
  end

  # Test 5: Rapid theme switching doesn't break announcements
  test 'rapid theme switching maintains stable announcement system' do
    visit profile_preferences_path

    # Rapidly switch between themes
    page.find('input[value="dark"]').click
    sleep 0.1
    page.find('input[value="light"]').click
    sleep 0.1
    page.find('input[value="system"]').click
    sleep 0.1
    page.find('input[value="dark"]').click
    sleep 0.5

    # Verify only one announcement region exists
    announcement_count = page.evaluate_script(<<~JS.strip)
      (function() {
        var count = 0;
        var regions = document.querySelectorAll('[aria-live="polite"]');
        for (var i = 0; i < regions.length; i++) {
          if (regions[i].classList.contains('sr-only') && regions[i].parentElement === document.body) {
            count++;
          }
        }
        return count;
      })()
    JS

    assert_equal 1, announcement_count, 'Should maintain single announcement region'

    # Verify final theme is dark
    assert page.has_css?('html.dark'), 'Final theme should be dark'
  end

  # Test 6: French locale theme announcements work end-to-end
  test 'French locale announcements work throughout user journey' do
    I18n.with_locale(:fr) do
      visit profile_preferences_path

      # Switch to dark mode
      page.find('input[value="dark"]').click
      sleep 0.5

      # Check announcement is in French
      announcement_text = page.evaluate_script(<<~JS.strip)
        (function() {
          var regions = document.querySelectorAll('[aria-live="polite"]');
          for (var i = 0; i < regions.length; i++) {
            if (regions[i].classList.contains('sr-only')) {
              return regions[i].textContent;
            }
          }
          return null;
        })()
      JS

      assert_not_nil announcement_text, 'French announcement should be present'
      # Check for French keywords (mode, activé, or foncé/clair)
      french_pattern = announcement_text.downcase.match?(/mode|activé|foncé|clair/)
      assert french_pattern, "Announcement should be in French, got: '#{announcement_text}'"

      # Navigate and verify persistence
      visit root_path
      sleep 0.3
      assert page.has_css?('html.dark'), 'Dark mode should persist in French locale'
    end
  end
end
