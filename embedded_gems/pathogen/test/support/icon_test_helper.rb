# frozen_string_literal: true

module IconTestHelper
  # Asserts that an icon with the given name is rendered
  # @param name [String, Symbol] The name of the icon
  # @param count [Integer] The expected number of icons (default: 1)
  # @param within [Capybara::Node::Element, nil] The element to search within (default: nil)
  def assert_icon(name, count: 1, within: nil)
    selector = "svg[data-phosphor-icon=\"#{name}\"]"
    if within
      within.all(selector, count: count)
    else
      assert_selector selector, count: count
    end
  end

  # Asserts that no icon with the given name is rendered
  # @param name [String, Symbol] The name of the icon
  # @param within [Capybara::Node::Element, nil] The element to search within (default: nil)
  def assert_no_icon(name, within: nil)
    selector = "svg[data-phosphor-icon=\"#{name}\"]"
    if within
      assert_not within.has_selector?(selector), "Expected no icon with name #{name} to be rendered"
    else
      assert_no_selector selector
    end
  end
end

# Include the helper in the test case
ActiveSupport::TestCase.include(IconTestHelper)

# For system tests
if defined?(ActionDispatch::SystemTestCase)
  ActionDispatch::SystemTestCase.include(IconTestHelper)
end

# For view component tests
if defined?(ViewComponent::TestHelpers)
  ViewComponent::TestHelpers.include(IconTestHelper)
end
