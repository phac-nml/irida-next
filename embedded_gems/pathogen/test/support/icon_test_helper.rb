# frozen_string_literal: true

# IconTestHelper provides Capybara-based assertions for verifying the presence or absence
# of SVG icons rendered with a specific data attribute. Intended for use in component,
# system, and standard test cases. Ensures consistent icon rendering checks across test suites.
#
# Usage examples:
#   assert_icon(:plus) # Asserts one icon with data-phosphor-icon="plus" is present
#   assert_icon(:check, count: 2, within: some_element)
#   assert_no_icon(:x)
#
# This helper is automatically included in ActiveSupport::TestCase, ActionDispatch::SystemTestCase,
# and ViewComponent::TestHelpers if available.
module IconTestHelper
  # Assert that an SVG icon with the given name is rendered.
  #
  # @param name [String, Symbol] The icon name (e.g., :plus, "check")
  # @param count [Integer] The expected number of icons (default: 1)
  # @param within [Capybara::Node::Element, nil] Optional Capybara element to scope the search
  #
  # @example Assert a single icon globally
  #   assert_icon(:plus)
  #
  # @example Assert two icons within a specific element
  #   assert_icon(:check, count: 2, within: some_element)
  def assert_icon(name, count: 1, within: nil)
    selector = "svg[data-phosphor-icon=\"#{name}\"]"
    if within
      within.all(selector, count: count)
    else
      assert_selector selector, count: count
    end
  end

  # Assert that no SVG icon with the given name is rendered.
  #
  # @param name [String, Symbol] The icon name (e.g., :plus, "check")
  # @param within [Capybara::Node::Element, nil] Optional Capybara element to scope the search
  #
  # @example Assert no icon globally
  #   assert_no_icon(:x)
  #
  # @example Assert no icon within a specific element
  #   assert_no_icon(:x, within: some_element)
  def assert_no_icon(name, within: nil)
    selector = "svg[data-phosphor-icon=\"#{name}\"]"
    if within
      assert_not within.has_selector?(selector), "Expected no icon with name #{name} to be rendered"
    else
      assert_no_selector selector
    end
  end
end

# Automatically include IconTestHelper in all test cases for convenience.
ActiveSupport.on_load(:active_support_test_case) { include IconTestHelper }

# Include in system tests if available.
if defined?(ActionDispatch::SystemTestCase)
  ActiveSupport.on_load(:action_dispatch_system_test_case) do
    include IconTestHelper
  end
end

# Include in ViewComponent tests if available.
ViewComponent::TestHelpers.include(IconTestHelper) if defined?(ViewComponent::TestHelpers)
