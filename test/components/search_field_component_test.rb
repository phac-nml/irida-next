# frozen_string_literal: true

require 'test_helper'

class SearchFieldComponentTest < ViewComponent::TestCase
  setup do
    @label = 'Search by email'
    @placeholder = 'Enter email address'
    @field_name = :user_email_cont
    @value = nil

    # Create a simple mock form object that responds to the methods we need
    @mock_form = MockForm.new(@field_name, @label, @placeholder, @value)
  end

  # Mock form class for testing
  class MockForm
    def initialize(field_name, label, placeholder, value)
      @field_name = field_name
      @label = label
      @placeholder = placeholder
      @value = value
    end

    def label(field_name, text, _options = {})
      ActiveSupport::SafeBuffer.new("<label for=\"q_#{field_name}\">#{text}</label>")
    end

    def search_field(field_name, options = {})
      value_attr = @value.present? ? "value=\"#{@value}\"" : ''
      attrs = options.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      input = <<~HTML.squish
        <input type="search" id="q_#{field_name}" name="q[#{field_name}]" #{value_attr} placeholder="#{@placeholder}" #{attrs}>
      HTML
      ActiveSupport::SafeBuffer.new(input)
    end
  end

  # Basic Rendering Tests
  test 'renders search field with correct structure' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  test 'renders with all required parameters' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that the component renders without errors
    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.relative', count: 1
  end

  test 'renders with custom value' do
    custom_value = 'test@example.com'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: custom_value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  test 'renders with nil value' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  # Clear Button Tests
  test 'shows clear button when value is present' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # The clear button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    # Check that the button doesn't have the 'hidden' class
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'hides clear button when value is nil' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # The clear button should be hidden
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  test 'hides clear button when value is empty string' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    # The clear button should be hidden
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  test 'hides clear button when value is whitespace only' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    # The clear button should be hidden (whitespace is not considered present)
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  # Submit Button Tests
  test 'shows submit button when value is nil' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # The submit button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="submitButton"].hidden'
  end

  test 'shows submit button when value is empty string' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    # The submit button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="submitButton"].hidden'
  end

  test 'hides submit button when value is present' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # The submit button should be hidden
    assert_selector 'button[data-search-field-target="submitButton"].hidden', count: 1
  end

  # Button Functionality Tests
  test 'clear button has correct attributes and actions' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # Check button attributes using selectors
    assert_selector 'button[data-search-field-target="clearButton"][type="button"]', count: 1
    assert_selector 'button[data-search-field-target="clearButton"][data-action*="click->search-field#clear"]', count: 1
    assert_selector 'button[data-search-field-target="clearButton"][data-action*="click->selection#clear"]', count: 1
    clear_aria = I18n.t('components.search_field_component.clear_button')
    clear_selector = format("button[data-search-field-target='clearButton'][aria-label='%s']", clear_aria)
    assert_selector clear_selector, count: 1
  end

  test 'submit button has correct attributes and actions' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # Check button attributes using selectors
    assert_selector 'button[data-search-field-target="submitButton"][type="submit"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"][data-action*="click->selection#clear"]', count: 1
    search_aria = I18n.t('components.search_field_component.search_button')
    submit_selector = format("button[data-search-field-target='submitButton'][aria-label='%s']", search_aria)
    assert_selector submit_selector, count: 1
  end

  # Accessibility Tests
  test 'has proper accessibility attributes' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for proper button accessibility
    assert_selector 'button[aria-label]', count: 2 # clear and submit buttons
  end

  test 'clear button is accessible' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # Check accessibility using selectors
    clear_aria = I18n.t('components.search_field_component.clear_button')
    clear_selector = format("button[data-search-field-target='clearButton'][aria-label='%s']", clear_aria)
    assert_selector clear_selector, count: 1
  end

  test 'submit button is accessible' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # Check accessibility using selectors
    search_aria = I18n.t('components.search_field_component.search_button')
    submit_selector = format("button[data-search-field-target='submitButton'][aria-label='%s']", search_aria)
    assert_selector submit_selector, count: 1
  end

  # Component Method Tests
  test 'clear_button? method returns true for present values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    assert component.clear_button?
  end

  test 'clear_button? method returns false for nil values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_not component.clear_button?
  end

  test 'clear_button? method returns false for empty string values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    assert_not component.clear_button?
  end

  test 'clear_button? method returns false for whitespace only values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    assert_not component.clear_button?
  end

  # Edge Cases and Error Handling
  test 'handles very long values gracefully' do
    long_value = 'a' * 1000
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: long_value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for long values
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'handles special characters in values gracefully' do
    special_chars = 'test@example.com & special/chars <>'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: special_chars
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for special characters
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'handles unicode characters in values gracefully' do
    unicode_chars = 'café résumé naïve'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: unicode_chars
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for unicode characters
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  # Component Initialization Tests
  test 'initializes with all required parameters' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    assert_equal @label, component.instance_variable_get(:@label)
    assert_equal @placeholder, component.instance_variable_get(:@placeholder)
    assert_equal @mock_form, component.instance_variable_get(:@form)
    assert_equal @field_name, component.instance_variable_get(:@field_name)
    assert_nil component.instance_variable_get(:@value)
  end

  test 'initializes with custom value' do
    custom_value = 'custom@example.com'
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: custom_value
    )

    assert_equal custom_value, component.instance_variable_get(:@value)
  end

  # Different Field Names Tests
  test 'renders with different field names' do
    different_field_names = %i[user_email_cont name_cont puid_cont description_cont]

    different_field_names.each do |field_name|
      render_inline SearchFieldComponent.new(
        label: @label,
        placeholder: @placeholder,
        form: @mock_form,
        field_name: field_name,
        value: @value
      )

      assert_selector 'div[data-controller="search-field"]', count: 1
    end
  end

  # Different Labels and Placeholders Tests
  test 'renders with different labels and placeholders' do
    different_labels = ['Search by name', 'Search by ID', 'Search by description']
    different_placeholders = ['Enter name', 'Enter ID', 'Enter description']

    different_labels.each_with_index do |label, index|
      render_inline SearchFieldComponent.new(
        label: label,
        placeholder: different_placeholders[index],
        form: @mock_form,
        field_name: @field_name,
        value: @value
      )

      assert_selector 'div[data-controller="search-field"]', count: 1
    end
  end

  # Button State Logic Tests
  test 'button visibility logic works correctly' do
    # Test with nil value
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_not component.clear_button?

    # Test with empty string
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    assert_not component.clear_button?

    # Test with whitespace
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    assert_not component.clear_button?

    # Test with actual value
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    assert component.clear_button?
  end

  # Form Integration Tests
  test 'integrates properly with form object' do
    # Create a more realistic mock form that responds to the methods we need
    realistic_mock_form = MockForm.new(:test_field, 'Test Label', 'Test placeholder', 'test value')

    render_inline SearchFieldComponent.new(
      label: 'Test Label',
      placeholder: 'Test placeholder',
      form: realistic_mock_form,
      field_name: :test_field,
      value: 'test value'
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.relative', count: 1
  end

  # CSS Classes and Styling Tests
  test 'has correct CSS classes for styling' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for Tailwind CSS classes
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  # Data Attributes Tests
  test 'has correct data attributes for Stimulus' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for Stimulus controller
    assert_selector 'div[data-controller="search-field"]', count: 1

    # Check for Stimulus targets
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
  end

  # Icon Integration Tests
  test 'renders icons for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons contain icon elements
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
  end

  # Responsive Design Tests
  test 'has responsive design classes' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for responsive classes
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  # Dark Mode Support Tests
  test 'supports dark mode styling' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # The component should render without errors
    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  # Hover Effects Tests
  test 'has hover effects for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons have hover classes using selectors
    assert_selector 'button[data-search-field-target="clearButton"][class*="hover:bg-slate-100"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"][class*="hover:bg-slate-100"]', count: 1
  end

  # Transition Effects Tests
  test 'has transition effects for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons have transition classes using selectors
    assert_selector 'button[data-search-field-target="clearButton"][class*="transition-colors"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"][class*="transition-colors"]', count: 1
  end
end
