# frozen_string_literal: true

require 'application_system_test_case'

# Test suite for screen reader announcements in the dark mode system
# These tests verify that theme changes trigger proper aria-live announcements
# and that announcements work correctly in both English and French locales
class DarkModeScreenReaderTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
  end

  test 'aria-live announcement element is created when colour mode controller connects' do
    visit profile_preferences_path

    # Verify the colour-mode controller creates an aria-live region
    has_polite_region = page.evaluate_script(<<~JS.strip)
      (function() {
        var regions = document.querySelectorAll('[aria-live="polite"]');
        for (var i = 0; i < regions.length; i++) {
          if (regions[i].classList.contains('sr-only')) {
            return true;
          }
        }
        return false;
      })()
    JS

    assert has_polite_region, 'Aria-live polite region with sr-only class should exist'
  end

  test 'aria-live region has correct attributes for screen reader compatibility' do
    visit profile_preferences_path

    # Check for polite aria-live region with atomic and sr-only
    attributes_check = page.evaluate_script(<<~JS.strip)
      (function() {
        var regions = document.querySelectorAll('[aria-live="polite"]');
        for (var i = 0; i < regions.length; i++) {
          var el = regions[i];
          if (el.classList.contains('sr-only')) {
            return {
              ariaAtomic: el.getAttribute('aria-atomic'),
              hasClass: true
            };
          }
        }
        return null;
      })()
    JS

    assert_not_nil attributes_check, 'Should find announcement element'
    assert_equal 'true', attributes_check['ariaAtomic'], 'Should announce content atomically'
    assert attributes_check['hasClass'], 'Should have sr-only class for visual hiding'
  end

  test 'theme change to dark mode triggers screen reader announcement in English' do
    I18n.with_locale(:en) do
      visit profile_preferences_path

      # Find and click the dark mode radio button
      dark_radio = page.find('input[value="dark"]')
      dark_radio.click
      sleep 0.5 # Allow announcement to be set

      # Check the announcement text
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
      assert_includes announcement_text.downcase, 'dark', 'Announcement should mention dark theme'
    end
  end

  test 'theme change to light mode triggers screen reader announcement in English' do
    I18n.with_locale(:en) do
      visit profile_preferences_path

      # Find and click the light mode radio button
      light_radio = page.find('input[value="light"]')
      light_radio.click
      sleep 0.5 # Allow announcement to be set

      # Check the announcement text
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
      assert_includes announcement_text.downcase, 'light', 'Announcement should mention light theme'
    end
  end

  test 'theme change to system mode triggers screen reader announcement in English' do
    I18n.with_locale(:en) do
      visit profile_preferences_path

      # First switch to a different mode
      page.find('input[value="dark"]').click
      sleep 0.3

      # Then switch to system mode
      system_radio = page.find('input[value="system"]')
      system_radio.click
      sleep 0.5 # Allow announcement to be set

      # Check the announcement text
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
      assert_includes announcement_text.downcase, 'system', 'Announcement should mention system theme'
    end
  end

  test 'theme announcements work correctly in French locale' do
    I18n.with_locale(:fr) do
      visit profile_preferences_path

      # Switch to dark mode
      dark_radio = page.find('input[value="dark"]')
      dark_radio.click
      sleep 0.5 # Allow announcement to be set

      # Check the announcement text is in French
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

      assert_not_nil announcement_text, 'Announcement should be present in French'
      # French translations should contain "foncé" for dark or "mode"
      assert announcement_text.downcase.include?('foncé') || announcement_text.downcase.include?('mode'),
             "Announcement should be in French: got '#{announcement_text}'"
    end
  end

  test 'announcement element is cleaned up when navigating away from preferences page' do
    visit profile_preferences_path

    # Verify announcement element exists on preferences page
    initial_count = page.evaluate_script(<<~JS.strip)
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
    assert initial_count.positive?, 'Announcement element should exist on preferences page'

    # Navigate away
    visit root_path

    # The announcement element should not persist (it's controller-specific)
    final_count = page.evaluate_script(<<~JS.strip)
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

    # After navigation, the colour-mode specific announcement should be gone
    assert_equal 0, final_count, 'Colour-mode announcement element should be cleaned up'
  end

  test 'multiple rapid theme changes do not create multiple announcement regions' do
    visit profile_preferences_path

    # Rapidly change themes
    page.find('input[value="dark"]').click
    sleep 0.1
    page.find('input[value="light"]').click
    sleep 0.1
    page.find('input[value="system"]').click
    sleep 0.5

    # Count announcement regions created by colour-mode controller
    announcement_count = page.evaluate_script(<<~JS.strip)
      (function() {
        var count = 0;
        var regions = document.querySelectorAll('[aria-live="polite"]');
        for (var i = 0; i < regions.length; i++) {
          if (regions[i].parentElement === document.body && regions[i].classList.contains('sr-only')) {
            count++;
          }
        }
        return count;
      })()
    JS

    assert_equal 1, announcement_count, 'Should only have one announcement region from colour-mode controller'
  end
end
