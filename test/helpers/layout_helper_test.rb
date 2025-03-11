# frozen_string_literal: true

require 'test_helper'

# Tests for the LayoutHelper module
#
# The LayoutHelper provides functionality for nested layouts in Rails applications.
# These tests ensure that the helper works correctly in various scenarios:
# - Valid layout rendering
# - Input validation
# - Error handling
class LayoutHelperTest < ActionView::TestCase
  # Test that parent_layout raises ArgumentError when layout name is nil
  #
  # This test verifies that the parent_layout method properly validates its input
  # and raises an ArgumentError with an appropriate message when nil is provided.
  test 'parent_layout raises ArgumentError when layout name is nil' do
    error = assert_raises(ArgumentError) do
      parent_layout(nil)
    end

    assert_equal 'Layout name cannot be nil or empty', error.message
  end

  # Test that parent_layout raises ArgumentError when layout name is empty
  #
  # This test verifies that the parent_layout method properly validates its input
  # and raises an ArgumentError with an appropriate message when an empty string is provided.
  test 'parent_layout raises ArgumentError when layout name is empty' do
    error = assert_raises(ArgumentError) do
      parent_layout('')
    end

    assert_equal 'Layout name cannot be nil or empty', error.message
  end

  # Test that parent_layout raises ArgumentError when layout name is only whitespace
  #
  # This test verifies that the parent_layout method properly validates its input
  # and raises an ArgumentError with an appropriate message when a string with only whitespace is provided.
  test 'parent_layout raises ArgumentError when layout name is only whitespace' do
    error = assert_raises(ArgumentError) do
      parent_layout('   ')
    end

    assert_equal 'Layout name cannot be nil or empty', error.message
  end

  # Test that parent_layout renders the parent layout
  #
  # This test verifies that the parent_layout method:
  # 1. Stores the current output buffer in the view flow
  # 2. Renders the parent layout template
  # 3. Sets the output buffer to the rendered parent layout
  #
  # The test uses method overriding to track method calls and verify behavior.
  test 'parent_layout with valid layout name renders the parent layout' do
    layout_name = 'application'

    # Create a mock view_flow
    mock_view_flow = Object.new
    def mock_view_flow.set(key, value)
      # This method is called with :layout and the output buffer
      @key = key
      @value = value
    end

    # Track if view_flow.set was called
    def mock_view_flow.set_called?
      defined?(@key) && defined?(@value)
    end

    # Create a mock output buffer
    mock_output_buffer = 'Current layout content'

    # Create a mock output for render
    mock_render_output = 'Parent layout content'

    # Create a flag to track if render was called with correct arguments
    render_called_correctly = false

    # Override helper methods for testing
    helper_instance = self
    helper_instance.define_singleton_method(:view_flow) { mock_view_flow }
    helper_instance.define_singleton_method(:output_buffer) { mock_output_buffer }
    helper_instance.define_singleton_method(:render) do |options|
      return unless options == { template: "layouts/#{layout_name}" }

      render_called_correctly = true
      mock_render_output
    end

    # Track if output_buffer= was called
    output_buffer_set = false
    helper_instance.define_singleton_method(:output_buffer=) do |value|
      output_buffer_set = true
      # In a real scenario, this would be set to the new buffer
    end

    # Call the method
    parent_layout(layout_name)

    # Assert that the expected methods were called
    assert render_called_correctly, 'render was not called with the expected arguments'
    assert mock_view_flow.set_called?, 'view_flow.set was not called'
    assert output_buffer_set, 'output_buffer= was not called'
  end

  # Test that parent_layout logs and re-raises errors
  #
  # This test verifies that when an error occurs during rendering:
  # 1. The error is logged with a descriptive message
  # 2. The original error is re-raised to the caller
  #
  # This ensures proper error handling and debugging capabilities.
  test 'parent_layout logs and re-raises error when layout rendering fails' do
    layout_name = 'non_existent_layout'
    render_error = StandardError.new('Layout not found')

    # Create a mock view_flow
    mock_view_flow = Object.new
    def mock_view_flow.set(key, value)
      # This method is called with :layout and the output buffer
    end

    # Create a mock output buffer
    mock_output_buffer = 'Current layout content'

    # Track if logger.error was called
    logger_called = false
    expected_log_message = "❌ Error rendering parent layout '#{layout_name}': Layout not found"

    # Override helper methods for testing
    helper_instance = self
    helper_instance.define_singleton_method(:view_flow) { mock_view_flow }
    helper_instance.define_singleton_method(:output_buffer) { mock_output_buffer }

    # Stub render to raise an error
    helper_instance.define_singleton_method(:render) do |options|
      return unless options == { template: "layouts/#{layout_name}" }

      raise render_error
    end

    # Stub Rails.logger.error
    original_logger = Rails.logger
    begin
      mock_logger = Object.new
      mock_logger.define_singleton_method(:error) do |message|
        logger_called = true if message == expected_log_message
      end
      Rails.logger = mock_logger

      # Call the method and expect it to raise
      error = assert_raises(StandardError) do
        parent_layout(layout_name)
      end

      # Verify the error is re-raised
      assert_equal render_error, error

      # Verify logger was called
      assert logger_called, 'Rails.logger.error was not called with the expected message'
    ensure
      # Restore original logger
      Rails.logger = original_logger
    end
  end
end
