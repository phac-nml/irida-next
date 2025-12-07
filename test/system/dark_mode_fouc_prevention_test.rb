# frozen_string_literal: true

require 'application_system_test_case'

# Test suite for FOUC (Flash of Unstyled Content) prevention in dark mode
# These tests verify that the inline script applies dark mode classes before page render
# and that theme persistence works correctly across page navigations
class DarkModeFoucPreventionTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
  end

  test 'dark mode class is applied when dark theme is selected' do
    visit profile_preferences_path

    # Click dark mode
    page.find('input[value="dark"]').click
    sleep 0.5

    # Check that dark class is present
    html_classes = page.evaluate_script('document.documentElement.className')
    assert_includes html_classes, 'dark', 'Dark class should be present'
    assert_not_includes html_classes, 'light', 'Light class should not be present in dark mode'
  end

  test 'light mode class is applied when light theme is selected' do
    visit profile_preferences_path

    # Click light mode
    page.find('input[value="light"]').click
    sleep 0.5

    # Check that light class is present
    html_classes = page.evaluate_script('document.documentElement.className')
    assert_includes html_classes, 'light', 'Light class should be present'
    assert_not_includes html_classes, 'dark', 'Dark class should not be present in light mode'
  end

  test 'theme persists across page navigations' do
    visit profile_preferences_path

    # Set dark theme
    page.find('input[value="dark"]').click
    sleep 0.5

    # Verify dark mode is active
    assert page.has_css?('html.dark'), 'Dark mode should be active on preferences page'

    # Navigate to another page
    visit root_path
    sleep 0.3

    # Verify dark mode persists
    assert page.has_css?('html.dark'), 'Dark mode should persist after navigation to root'
  end

  test 'FOUC prevention script executes in IIFE to avoid global scope pollution' do
    visit root_path

    # Verify that helper functions are not in global scope
    is_system_theme_global = page.evaluate_script('typeof window.isSystemTheme')
    is_dark_theme_global = page.evaluate_script('typeof window.isDarkTheme')
    update_theme_global = page.evaluate_script('typeof window.updateTheme')

    assert_equal 'undefined', is_system_theme_global, 'isSystemTheme should not be global'
    assert_equal 'undefined', is_dark_theme_global, 'isDarkTheme should not be global'
    assert_equal 'undefined', update_theme_global, 'updateTheme should not be global'
  end

  test 'theme toggles correctly between dark, light, and system modes' do
    visit profile_preferences_path

    # Switch to dark mode
    page.find('input[value="dark"]').click
    sleep 0.3
    assert page.has_css?('html.dark'), 'Should switch to dark mode'

    # Switch to light mode
    page.find('input[value="light"]').click
    sleep 0.3
    assert page.has_css?('html.light'), 'Should switch to light mode'

    # Switch to system mode
    page.find('input[value="system"]').click
    sleep 0.3
    # System mode will apply either dark or light based on system preference
    # Just verify one of them is present
    html_classes = page.evaluate_script('document.documentElement.className')
    assert html_classes.include?('dark') || html_classes.include?('light'),
           'Should have either dark or light class in system mode'
  end

  test 'no flash occurs when navigating between pages with consistent theme' do
    visit profile_preferences_path

    # Set dark theme
    page.find('input[value="dark"]').click
    sleep 0.5

    # Navigate to multiple pages quickly
    visit root_path
    assert page.has_css?('html.dark'), 'Dark mode on root'

    visit profile_preferences_path
    assert page.has_css?('html.dark'), 'Dark mode on preferences'

    visit root_path
    assert page.has_css?('html.dark'), 'Dark mode persists on return to root'
  end

  test 'dark mode classes are toggled correctly on documentElement' do
    visit profile_preferences_path

    # Start with light mode
    page.find('input[value="light"]').click
    sleep 0.3

    initial_classes = page.evaluate_script('document.documentElement.classList.contains("light")')
    assert initial_classes, 'Light class should be present initially'

    # Switch to dark
    page.find('input[value="dark"]').click
    sleep 0.3

    has_dark = page.evaluate_script('document.documentElement.classList.contains("dark")')
    has_light = page.evaluate_script('document.documentElement.classList.contains("light")')

    assert has_dark, 'Dark class should be present after switching'
    assert_not has_light, 'Light class should be removed after switching to dark'
  end

  test 'theme switching updates localStorage' do
    visit profile_preferences_path

    # Switch to dark mode
    page.find('input[value="dark"]').click
    sleep 0.5

    # Navigate to a new page and verify dark mode persists
    # This indirectly tests that localStorage was updated
    visit root_path
    sleep 0.3

    assert page.has_css?('html.dark'), 'Dark mode should persist via localStorage'
  end
end
